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
    widget.no_show_all = !visible;
    widget.visible = visible;
}

public class AppEditor.MainWindow : Gtk.Dialog {
    private const string MAIN_GRID_ID = "main-grid";
    private const string LOADING_GRID_ID = "loading-grid";
    private const string NO_APPS_GRID_ID = "no-apps-grid";

    private Gtk.Stack stack;
    private Gtk.Revealer search_revealer;
    private Gtk.SearchEntry search_entry;
    private Sidebar sidebar;
    private AppInfoViewStack app_info_view_stack;

    construct {
        sidebar = new Sidebar ();
        sidebar.app_selected.connect (on_app_selected);

        app_info_view_stack = new AppInfoViewStack ();
        app_info_view_stack.view_removed.connect (on_view_removed);

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

        unowned Gtk.Box content_area = get_content_area ();
        content_area.add (stack);

        search_entry = new Gtk.SearchEntry ();
        search_entry.placeholder_text = _("Find…");
        search_entry.changed.connect (() => sidebar.set_current_search_query (search_entry.text));

        search_revealer = new Gtk.Revealer ();
        search_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        search_revealer.add (search_entry);

        var new_button = new Gtk.Button.from_icon_name ("document-new", Gtk.IconSize.LARGE_TOOLBAR);
        new_button.tooltip_text = _("New entry");
        new_button.clicked.connect (on_new_button_clicked);

        var header_bar = (Gtk.HeaderBar)get_header_bar ();
        header_bar.pack_start (new_button);
        header_bar.pack_start (search_revealer);

        monitor_manager_state ();
    }

    public MainWindow () {
        Object (
            title: Constants.APP_NAME,
            width_request: 1000,
            height_request: 700,
            use_header_bar: (int)true
        );
    }

    public override void show_all () {
        base.show_all ();
        search_entry.grab_focus ();
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

    private void set_loaded (bool loaded) {
        if (loaded) {
            var manager = DesktopAppManager.get_default ();
            var app_list = manager.get_app_list ();
            if (app_list.size > 0) {
                stack.visible_child_name = MAIN_GRID_ID;
                search_revealer.reveal_child = true;

                refill_sidebar ();
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
            sidebar.add_app (desktop_app);
        }
    }

    private void on_app_selected (AppItem item) {
        app_info_view_stack.show_app_info (item.desktop_app);
    }

    private void on_view_removed (AppInfoView view) {
        sidebar.remove_app (view.desktop_app);
    }

    private void on_new_button_clicked () {
        var new_app = AppInfoViewSaver.create_new_local_app ();
        sidebar.add_app (new_app, true);
    }
}
