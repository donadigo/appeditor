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

public class AppEditor.DesktopApp : Object {
    public const char DEFAULT_LIST_SEPARATOR = ';';
    public const string LOCAL_APP_NAME_PREFIX = "appeditor-local-application-";
    public const string LOCAL_APP_NAME_SUFFIX = ".desktop";

    private const string DEFAULT_ICON_NAME = "application-x-executable";

    public signal void changed ();

    private string? display_name = null;
    private string? description = null;
    private Icon? icon = null;
    private string? commandline = null;
    private string? path = null;
    private string[]? categories = null;
    private AppCategory? main_category = null;

    public DesktopAppInfo info { get; construct set; }

    private static Icon default_icon;

    static construct {
        default_icon = new ThemedIcon (DEFAULT_ICON_NAME);
    }

    construct {
        notify["info"].connect (reset_values);
    }

    public static bool get_name_only_local (string name) {
        return name.has_prefix (LOCAL_APP_NAME_PREFIX) && name.has_suffix (LOCAL_APP_NAME_SUFFIX);
    }

    public DesktopApp (DesktopAppInfo info) {
        Object (info: info);
    }

    public void open_default_handler (Gdk.Screen? screen) throws Error {
        var file = File.new_for_path (info.get_filename ());
        try {
            Gtk.show_uri (screen, file.get_uri (), Gtk.get_current_event_time ());
        } catch (Error e) {
            throw e;
        }
    }

    public bool get_only_local () {
        string basename = get_basename ();
        if (get_name_only_local (basename)) {
            return true;
        }

        return AppDirectoryScanner.get_desktop_id_count (basename) <= 1;
    }

    public bool compare (DesktopApp other) {
        return info.get_filename () == other.info.get_filename ();
    }

    public unowned string get_display_name () {
        if (display_name == null) {
            display_name = info.get_display_name ();
        }

        return display_name;
    }

    public string get_basename () {
        return Path.get_basename (info.get_filename ());
    }

    public unowned string get_description () {
        if (description == null) {
            unowned string desc = info.get_description ();
            if (desc == null) {
                desc = "";
            }

            description = desc;
        }

        return description;
    }

    public Icon get_icon () {
        if (icon == null) {
            var _icon = info.get_icon ();
            if (_icon == null) {
                _icon = default_icon;
            }

            icon = _icon;
        }

        return icon;
    }

    public unowned string get_commandline () {
        if (commandline == null) {
            unowned string cmdline = info.get_commandline ();
            if (cmdline == null) {
                cmdline = "";
            }

            commandline = cmdline;
        }

        return commandline;
    }

    public unowned string get_path () {
        if (path == null) {
            unowned string _path = info.get_string (KeyFileDesktop.KEY_PATH);
            if (_path == null) {
                _path = "";
            }

            path = _path;
        }

        return path;
    }

    public bool get_terminal () {
        return info.get_boolean (KeyFileDesktop.KEY_TERMINAL);
    }

    public bool get_display () {
        return !info.get_nodisplay ();
    }

    public bool get_should_show () {
        return info.should_show () && !get_terminal (); 
    }

    public string[] get_categories () {
        if (categories == null) {
            categories = {};
            unowned string unparsed = info.get_categories ();
            if (unparsed != null) {
                categories = unparsed.split (DEFAULT_LIST_SEPARATOR.to_string ());
            }
        }

        return categories;
    }

    public AppCategory get_main_category () {
        if (main_category == null) {
            var menu_categories = DesktopAppManager.get_menu_cateogries ();
            foreach (string category in get_categories ()) {
                foreach (var menu_category in menu_categories) {
                    if (category == menu_category.id) {
                        main_category = menu_category;
                        break;
                    }
                }
            }

            if (main_category == null) {
                main_category = DesktopAppManager.get_default_category ();
            }
        }

        return main_category;
    }

    private void reset_values () {
        display_name = null;
        description = null;
        icon = null;
        commandline = null;
        path = null;
        categories = null;
        main_category = null;
        changed ();
    }
}
