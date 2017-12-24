/*-
 * Copyright (c) 2017 Adam Bieńkowski
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

public static void set_widget_visible (Gtk.Widget widget, bool visible) {
    if (visible) {
        widget.no_show_all = false;
        widget.show_all ();
    } else {
        widget.no_show_all = true;
        widget.hide ();
    }
}

public class AppEditor.MainWindow : Gtk.Window {
    private const string MAIN_GRID_ID = "main-grid";
    private const string LOADING_GRID_ID = "loading-grid";
    private const string NO_APPS_GRID_ID = "no-apps-grid";

    private static Settings settings;

    private Gtk.Stack stack;
    private Gtk.Revealer search_revealer;
    private Gtk.SearchEntry search_entry;
    private Gtk.Switch show_hidden_switch;
    private AppSourceList app_source_list;
    private AppInfoViewStack app_info_view_stack;
    
    static construct {
        settings = new Settings (Constants.SETTINGS_SCHEMA);
    }

    construct {
        app_source_list = new AppSourceList ();
        app_source_list.app_selected.connect (on_app_selected);

        app_info_view_stack = new AppInfoViewStack ();
        app_info_view_stack.view_removed.connect (on_view_removed);

        var show_hidden_label = new Gtk.Label (_("Show hidden entries"));
        show_hidden_label.get_style_context ().add_class ("h4");
        show_hidden_label.margin_start = 6;

        show_hidden_switch = new Gtk.Switch ();
        show_hidden_switch.margin_top = 12;
        show_hidden_switch.margin_bottom = 12;
        show_hidden_switch.margin_start = 12;
        show_hidden_switch.margin_end = 6;
        show_hidden_switch.notify["active"].connect (on_show_hidden_switch_active_changed);

        settings.bind ("show-hidden-entries", show_hidden_switch, "active", SettingsBindFlags.DEFAULT);

        var action_bar = new Gtk.ActionBar ();
        action_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        action_bar.pack_start (show_hidden_label);
        action_bar.pack_end (show_hidden_switch);

        var sidebar = new Gtk.Grid ();
        sidebar.attach (app_source_list, 0, 0, 1, 1);
        sidebar.attach (action_bar, 0, 1, 1, 1);

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned.width_request = 250;
        paned.position = 240;
        paned.hexpand = true;
        paned.pack1 (sidebar, false, false);
        paned.pack2 (app_info_view_stack, true, false);

        var main_grid = new Gtk.Grid ();
        main_grid.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, 0, 1, 1);
        main_grid.attach (paned, 0, 1, 1, 1);
        main_grid.show_all ();

        var spinner = new Gtk.Spinner ();
        spinner.expand = true;
        spinner.halign = Gtk.Align.CENTER;
        spinner.valign = Gtk.Align.CENTER;
        spinner.start ();

        var loading_grid = new Gtk.Grid ();
        loading_grid.attach (spinner, 0, 0, 1, 1);
        loading_grid.show_all ();

        var no_apps_view = new Granite.Widgets.AlertView (_("No Applications Found"), _("Could not find any applications to edit on this system"), "dialog-error");
        no_apps_view.show_action (_("Retry"));

        var no_apps_grid = new Gtk.Grid ();
        no_apps_grid.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, 0, 1, 1);
        no_apps_grid.attach (no_apps_view, 0, 1, 1, 1);
        no_apps_grid.show_all ();

        stack = new Gtk.Stack ();
        stack.add_named (main_grid, MAIN_GRID_ID);
        stack.add_named (loading_grid, LOADING_GRID_ID);
        stack.add_named (no_apps_grid, NO_APPS_GRID_ID);
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        add (stack);

        search_entry = new Gtk.SearchEntry ();
        search_entry.placeholder_text = _("Find…");
        search_entry.changed.connect (() => app_source_list.search_query = search_entry.text);

        search_revealer = new Gtk.Revealer ();
        search_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        search_revealer.add (search_entry);

        var new_button = new Gtk.Button.from_icon_name ("document-new", Gtk.IconSize.LARGE_TOOLBAR);
        new_button.tooltip_text = _("New entry");
        new_button.clicked.connect (on_new_button_clicked);

        var header_bar = new Gtk.HeaderBar ();
        header_bar.show_close_button = true;
        header_bar.pack_start (new_button);
        header_bar.pack_start (search_revealer);
        set_titlebar (header_bar);

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("com/github/donadigo/appeditor/application.css");
        Gtk.StyleContext.add_provider_for_screen (get_screen (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        int x = settings.get_int ("window-x");
        int y = settings.get_int ("window-y");

        if (x != -1 && y != -1) {
            move (x, y);
        }

        monitor_manager_state ();
        Unix.signal_add (Posix.SIGINT, signal_source_func, Priority.HIGH);
        Unix.signal_add (Posix.SIGTERM, signal_source_func, Priority.HIGH);
    }

    public MainWindow () {
        Object (
            title: Constants.APP_NAME,
            width_request: 1000,
            height_request: 700
        );
    }

    public override void show_all () {
        base.show_all ();
        search_entry.grab_focus ();
    }

    public override bool delete_event (Gdk.EventAny event) {
        int x, y;
        get_position (out x, out y);

        settings.set_int ("window-x", x);
        settings.set_int ("window-y", y);

        
        var current_view = app_info_view_stack.get_current_view ();

        string selected_desktop_id;
        if (current_view != null) {
            selected_desktop_id = current_view.desktop_app.get_basename ();
        } else {
            selected_desktop_id = "";
        }

        settings.set_string ("selected-desktop-id", selected_desktop_id);

        hide ();
        save_all ();
        return false;
    }

    private bool signal_source_func () {
        close ();
        return true;
    }

    private void monitor_manager_state () {
        var manager = DesktopAppManager.get_default ();
        if (manager.loaded) {
            set_loaded (true);
        } else {
            set_loaded (false);

            ulong signal_id = 0;
            signal_id = manager.notify["loaded"].connect (() => {
                manager.disconnect (signal_id);
                set_loaded (manager.loaded);
            });
        }
    }

    private void save_all () {
        var unsaved_views = app_info_view_stack.get_unsaved_views ();
        if (unsaved_views.size > 0) {
            var loop = new MainLoop ();

            int i = 0;
            foreach (var view in unsaved_views) {
                view.save.begin (true, () => {
                    if (i == unsaved_views.size) {
                        loop.quit ();
                    }
                });

                i++;
            }
            
            loop.run ();
        }
    }

    private void set_loaded (bool loaded) {
        if (loaded) {
            var manager = DesktopAppManager.get_default ();
            var app_list = manager.get_app_list ();
            if (app_list.size > 0) {
                stack.visible_child_name = MAIN_GRID_ID;
                search_revealer.reveal_child = true;
 
                refill_sidebar ();

                string selected_desktop_id = settings.get_string ("selected-desktop-id");
                if (selected_desktop_id != "") {
                    app_source_list.select_desktop_id (selected_desktop_id);
                }
            } else {
                stack.visible_child_name = NO_APPS_GRID_ID;
                search_revealer.reveal_child = false;
            }
        } else {
            stack.visible_child_name = LOADING_GRID_ID;
            search_revealer.reveal_child = false;
        }
    }

    private void refill_sidebar () {
        var manager = DesktopAppManager.get_default ();
        foreach (var desktop_app in manager.get_app_list ()) {
            app_source_list.add_app (desktop_app);
        }
    }

    private void on_app_selected (AppItem item) {
        app_info_view_stack.show_app_info (item.desktop_app);
    }

    private void on_view_removed (AppInfoView view) {
        app_source_list.remove_app (view.desktop_app);
    }

    private void on_new_button_clicked () {
        search_entry.text = "";

        var new_app = AppInfoViewSaver.create_new_local_app ();
        app_source_list.add_app (new_app, true);
    }

    private void on_show_hidden_switch_active_changed () {
        app_source_list.show_hidden_entries = show_hidden_switch.active;
    }
}
