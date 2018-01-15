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

public class AppEditor.AppInfoView : Gtk.Box {
    public DesktopApp desktop_app { get; construct set; }
    public signal void removed ();

    public string save_display_name {
        get {
            return name_entry.text;
        }
    }

    public string save_description {
        get {
            return comment_entry.text;
        }
    }

    public string save_icon {
        owned get {
            return icon_button.icon.to_string ();
        }
    }

    public bool save_display {
        get {
            return display_switch.active;
        }
    }

    public string save_category {
        owned get {
            return category_combo_box.get_selected_category_id ();
        }
    }

    public string save_commandline {
        get {
            return cmdline_entry.text;
        }
    }

    public string save_working_path {
        get {
            return path_entry.text;
        }
    }

    public bool save_terminal {
        get {
            return terminal_switch.active;
        }
    }

    public bool uses_notifications {
        get {
            return notifications_switch.active;
        }
    }

    private static AppInfoViewSaver saver;

    private IconButton icon_button;
    private Gtk.Entry name_entry;
    private Gtk.Entry comment_entry;
    private Gtk.Switch display_switch;
    private CategoryComboBox category_combo_box;
    private Gtk.Entry cmdline_entry;
    private Gtk.Entry path_entry;
    private Gtk.Switch terminal_switch;
    private Gtk.Switch notifications_switch;

    private Gtk.Button save_button;
    private Gtk.Button restore_defaults_button;
    private Granite.Widgets.Toast toast;

    private Gtk.InfoBar error_info_bar;
    private Gtk.Label error_label;

    private File local_file;
    private bool cmdline_valid = false;

    static construct {
        saver = new AppInfoViewSaver ();
    }

    construct {
        icon_button = new IconButton ();
        icon_button.valign = Gtk.Align.START;
        icon_button.changed.connect (on_info_changed);

        var name_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        name_box.hexpand = true;

        name_entry = new PersistentPlaceholderEntry ();
        name_entry.placeholder_text = _("Display name");
        name_entry.get_style_context ().add_class ("h2");
        name_entry.valign = Gtk.Align.START;
        name_entry.margin_end = 60;
        name_entry.changed.connect (on_name_entry_changed);

        comment_entry = new PersistentPlaceholderEntry ();
        comment_entry.placeholder_text = _("Comment");
        comment_entry.get_style_context ().add_class ("h3");
        comment_entry.valign = Gtk.Align.START;
        comment_entry.margin_end = 60;
        comment_entry.changed.connect (on_info_changed);

        name_box.add (new FieldEntry (name_entry));
        name_box.add (new FieldEntry (comment_entry));

        display_switch = new Gtk.Switch ();
        display_switch.notify["active"].connect (on_info_changed);

        category_combo_box = new CategoryComboBox ();
        category_combo_box.set_current_desktop_app (desktop_app);
        category_combo_box.changed.connect (on_info_changed);

        var display_box = new SettingBox (_("Show in Launcher"), display_switch, false);
        var category_box = new SettingBox (_("Category"), category_combo_box, true);

        var visibility_settings_grid = new SettingsGrid (_("Visibility"));
        visibility_settings_grid.add_widget (display_box);
        visibility_settings_grid.add_widget (category_box);

        cmdline_entry = new PersistentPlaceholderEntry ();
        cmdline_entry.width_request = 300;
        cmdline_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        cmdline_entry.placeholder_text = _("Program to execute along with it's arguments");
        cmdline_entry.changed.connect (on_cmdline_entry_changed);

        path_entry = new PersistentPlaceholderEntry ();
        path_entry.width_request = 300;
        path_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        path_entry.placeholder_text = _("The working directory to run the program in");
        path_entry.changed.connect (on_info_changed);

        terminal_switch = new Gtk.Switch ();
        terminal_switch.notify["active"].connect (on_info_changed);

        var executable_box = new SettingBox (_("Command Line"), cmdline_entry, false);
        var path_box = new SettingBox (_("Working Directory"), path_entry, true);
        var terminal_box = new SettingBox (_("Launch in Terminal"), terminal_switch, true);

        var launch_settings_grid = new SettingsGrid (_("Launching"));
        launch_settings_grid.add_widget (executable_box);
        launch_settings_grid.add_widget (path_box);
        launch_settings_grid.add_widget (terminal_box);

        notifications_switch = new Gtk.Switch ();
        notifications_switch.notify["active"].connect (on_info_changed);

        var notifications_box = new SettingBox (_("Uses Notifications"), notifications_switch, false);

        var advanced_grid = new SettingsGrid (null);
        advanced_grid.margin_top = 6;
        advanced_grid.add_widget (notifications_box);

        var advanced_container = new Gtk.Grid ();
        advanced_container.add (advanced_grid);

        var advanced_expander = new Gtk.Expander (_("Advanced"));
        advanced_expander.add (advanced_container);

        var header_grid = new Gtk.Grid ();
        header_grid.column_spacing = 12;
        header_grid.row_spacing = 6;
        header_grid.margin_start = 24;
        header_grid.margin_end = 24;
        header_grid.margin_top = 24;
        header_grid.attach (icon_button, 0, 0, 1, 1);
        header_grid.attach (name_box, 1, 0, 1, 1);

        var settings_grid = new Gtk.Grid ();
        settings_grid.row_spacing = 12;
        settings_grid.margin_start = 24;
        settings_grid.margin_end = 24;
        settings_grid.attach (visibility_settings_grid, 0, 0, 1, 1);
        settings_grid.attach (launch_settings_grid, 0, 1, 1, 1);
        settings_grid.attach (advanced_expander, 0, 2, 1, 1);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (settings_grid);

        restore_defaults_button = new Gtk.Button ();
        restore_defaults_button.clicked.connect (on_restore_defaults_button_clicked);

        save_button = new Gtk.Button.with_label (_("Save"));
        save_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        save_button.sensitive = false;
        save_button.clicked.connect (() => save.begin ());

        var open_source_button = new Gtk.Button.with_label (_("Open in Text Editor"));
        open_source_button.clicked.connect (on_open_source_button_clicked);

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        size_group.add_widget (save_button);
        size_group.add_widget (restore_defaults_button);
        size_group.add_widget (open_source_button);

        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        button_box.margin = 6;
        button_box.pack_start (open_source_button, false, false);
        button_box.pack_end (save_button, false, false);
        button_box.pack_end (restore_defaults_button, false, false);

        var bottom_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        bottom_box.hexpand = true;
        bottom_box.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        bottom_box.add (button_box);

        toast = new Granite.Widgets.Toast ("");
        toast.halign = Gtk.Align.END;

        var overlay = new Gtk.Overlay ();
        overlay.add (header_grid);
        overlay.add_overlay (toast);

        error_label = new Gtk.Label (null);
        error_label.wrap = true;
        error_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        error_label.show_all ();

        error_info_bar = new Gtk.InfoBar ();
        error_info_bar.message_type = Gtk.MessageType.ERROR;
        error_info_bar.show_close_button = true;
        error_info_bar.response.connect (() => set_widget_visible (error_info_bar, false));
        set_widget_visible (error_info_bar, false);

        unowned Gtk.Container content = error_info_bar.get_content_area ();
        content.add (error_label);
        
        pack_start (error_info_bar, false, false);
        pack_start (overlay, false, false);
        add (scrolled);
        pack_end (bottom_box, false, false);

        string basename = desktop_app.get_basename ();
        string path = AppDirectoryScanner.get_config_path ();

        local_file = File.new_for_path (Path.build_filename (path, basename));
        monitor_local_file ();

        desktop_app.changed.connect (on_info_changed);
        update_page ();
    }

    public AppInfoView (DesktopApp desktop_app) {
        Object (
            desktop_app: desktop_app,
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 12
        );
    }

    public async void save (bool silent = false) {
        saver.target = this;
        try {
            yield saver.save ();

            toast.title = _("Changes successfully saved");
            toast.send_notification ();
        } catch (Error e) {
            set_widget_visible (error_info_bar, true);
            error_label.label = _("Something went wrong and the changes could not be saved: %s".printf (e.message));
        }

        validate_cmdline_entry ();
        update_restore_button ();
    }

    public bool get_changed () {
        return (
            icon_button.icon.to_string () != desktop_app.get_icon ().to_string () ||
            name_entry.text != desktop_app.get_display_name () ||
            comment_entry.text != desktop_app.get_description () ||
            display_switch.active != desktop_app.get_display () ||
            category_combo_box.get_selected_category_id () != desktop_app.get_main_category ().id ||
            cmdline_entry.text != desktop_app.get_commandline () ||
            path_entry.text != desktop_app.get_path () ||
            terminal_switch.active != desktop_app.get_terminal () ||
            notifications_switch.active != desktop_app.info.get_boolean (DesktopApp.USES_NOTIFICATIONS_KEY)
        );
    }

    private void monitor_local_file () {
        try {
            var file_monitor = local_file.monitor (FileMonitorFlags.NONE);
            file_monitor.changed.connect (() => on_info_changed ());
        } catch (Error e) {
            warning (e.message);
        }
    }

    private void on_name_entry_changed () {
        validate_name_entry ();
        on_info_changed ();
    }

    private void validate_name_entry () {
        if (name_entry.text == "") {
            name_entry.secondary_icon_name = "dialog-warning-symbolic";
            name_entry.secondary_icon_tooltip_text = _("No visible title in the applications menu");
        } else {
            name_entry.secondary_icon_name = "";
            name_entry.secondary_icon_tooltip_text = "";
        }
    }

    private void on_cmdline_entry_changed () {
        validate_cmdline_entry ();
        on_info_changed ();
    }

    private void validate_cmdline_entry () {
        if (cmdline_entry.text == "") {
            cmdline_entry.secondary_icon_name = "dialog-warning-symbolic";
            cmdline_entry.secondary_icon_tooltip_text = _("No program will be launched");
            cmdline_valid = true;
        } else if (cmdline_entry.text.split (" ")[0].contains ("=")) {
            cmdline_entry.secondary_icon_name = "dialog-error-symbolic";
            cmdline_entry.secondary_icon_tooltip_text = _("The executable name (first argument) cannot contain the equal sign");
            cmdline_valid = false;
        } else {
            if (cmdline_entry.text.has_prefix (Path.DIR_SEPARATOR_S) &&
                !FileUtils.test (cmdline_entry.text.split (" ")[0], FileTest.EXISTS)) {
                cmdline_entry.secondary_icon_name = "dialog-error-symbolic";
                cmdline_entry.secondary_icon_tooltip_text = _("Entered file does not exist");
                cmdline_valid = false;
            } else {
                string[] args = cmdline_entry.text.split (" ");
                if (Environment.find_program_in_path (args[0]) == null) {
                    cmdline_entry.secondary_icon_name = "dialog-error-symbolic";
                    cmdline_entry.secondary_icon_tooltip_text = _("Entered program was not found");
                    cmdline_valid = false;
                } else {
                    cmdline_entry.secondary_icon_name = "";
                    cmdline_entry.secondary_icon_tooltip_text = "";
                    cmdline_valid = true;
                }
            }
        }
    }

    private void on_info_changed () {
        save_button.sensitive = get_changed () && cmdline_valid;
        restore_defaults_button.sensitive = local_file.query_exists ();
    }

    private void on_restore_defaults_button_clicked () {
        unowned string title;
        unowned string description;
        unowned string button_title;

        if (desktop_app.get_only_local ()) {
            title = _("Do You Want to Delete This Entry?");
            description = _("Deleting this entry is permament and cannot be undone. This does not delete the application itself, only the entry shown in the applications menu.");
            button_title = _("Delete");
        } else {
            title = _("Do You Want to Restore The Defaults?");
            description = _("Restoring defaults will undo all the changes done to this entry.");
            button_title = _("Restore defaults");
        }

        var button = new Gtk.Button.with_label (button_title);
        button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        var dialog = new MessageDialog (title, description, "dialog-warning");
        dialog.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        dialog.add_action_widget (button, Gtk.ResponseType.APPLY);
        dialog.show_all ();

        if (dialog.run () == Gtk.ResponseType.APPLY) {
            if (local_file.query_exists ()) {
                try {
                    local_file.@delete ();
                } catch (Error e) {
                    warning (e.message);
                }
            }

            string? basename = local_file.get_basename ();
            if (basename != null) {
                var new_info = new DesktopAppInfo (basename);
                if (new_info != null) {
                    desktop_app.info = new_info;
                    update_page ();
                } else {
                    removed ();
                }
            }
        }

        dialog.destroy ();
    }

    private void on_open_source_button_clicked () {
        try {
            desktop_app.open_default_handler (get_screen ());
        } catch (Error e) {
            var dialog = new MessageDialog (_("Could Not Open This Entry"), e.message, "dialog-error");
            dialog.add_button (_("Close"), Gtk.ResponseType.CLOSE);
            dialog.show_all ();
            dialog.run ();
            dialog.destroy ();
        }
    }

    private void update_page () {
        icon_button.icon = desktop_app.get_icon ();
        name_entry.text = desktop_app.get_display_name ();
        comment_entry.text = desktop_app.get_description ();
        display_switch.active = desktop_app.get_display ();
        category_combo_box.set_current_desktop_app (desktop_app);
        cmdline_entry.text = desktop_app.get_commandline ();
        path_entry.text = desktop_app.get_path ();
        terminal_switch.active = desktop_app.get_terminal ();
        notifications_switch.active = desktop_app.info.get_boolean (DesktopApp.USES_NOTIFICATIONS_KEY);
        
        update_restore_button ();
    }

    private void update_restore_button () {
        if (desktop_app.get_only_local ()) {
            restore_defaults_button.label = _("Delete entry…");
        } else {
            restore_defaults_button.label = _("Restore defaults…");
        }
    }
}
