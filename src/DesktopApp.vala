/*-
 * Copyright 2021 Adam Bieńkowski <donadigos159@gmail.com>
 *
 * This program is free software: you can redistribute it
 * and/or modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be
 * useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 * Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see http://www.gnu.org/licenses/.
 */

 [DBus (name = "org.freedesktop.portal.OpenURI")]
public interface FDODesktopPortal : Object {
    public abstract string open_file (string parent_window, UnixInputStream fd, HashTable<string, Variant> options) throws GLib.Error;
}

public class AppEditor.DesktopApp : Object {
    public const char DEFAULT_LIST_SEPARATOR = ';';
    public const string LOCAL_APP_NAME_PREFIX = "appeditor-local-application-";
    public const string LOCAL_APP_NAME_SUFFIX = ".desktop";
    public const string USES_NOTIFICATIONS_KEY = "X-GNOME-UsesNotifications";

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
    private static FDODesktopPortal? desktop_portal = null;

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

    private static FDODesktopPortal? get_desktop_portal () throws Error {
        if (desktop_portal == null) {
            try {
                desktop_portal = Bus.get_proxy_sync (
                    BusType.SESSION,
                    "org.freedesktop.portal.Desktop",
                    "/org/freedesktop/portal/desktop"
                );
            } catch (Error e) {
                throw e;
            }
        }

        return desktop_portal;
    }

    public void open_default_handler () throws Error {
        // Gtk.show_uri_on_window does not seem to fully work in a Flatpak environment
        // so instead we directly call the freedesktop OpenURI DBus interface instead.
        int fd = Posix.open (info.get_filename (), Posix.O_RDONLY);
        try {
            var portal = get_desktop_portal ();
            if (portal != null) {
                portal.open_file ("", new UnixInputStream(fd, true), new GLib.HashTable<string, GLib.Variant> (null, null));
            }
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
            string _path = info.get_string (KeyFileDesktop.KEY_PATH);
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
            bool found = false;
            foreach (string category in get_categories ()) {
                foreach (var menu_category in menu_categories) {
                    if (category == menu_category.id) {
                        main_category = menu_category;
                        found = true;
                        break;
                    }
                }

                if (found) {
                    break;
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
