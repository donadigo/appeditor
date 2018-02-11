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

public class AppEditor.AppInfoViewSaver : Object {
    public AppInfoView target { get; set; }

    // TODO: make these functions fully async
    public static DesktopApp? create_new_local_app (AppCategory? category) throws Error {
        string lang = Intl.get_language_names ()[0];

        var key = new KeyFile ();
        key.set_list_separator (DesktopApp.DEFAULT_LIST_SEPARATOR);
        key.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_TYPE, KeyFileDesktop.TYPE_APPLICATION);
        key.set_locale_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_NAME, lang, _("New Application"));
        if (category != null) {
            string[] categories = { category.id };
            key.set_string_list (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_CATEGORIES, categories);
        }

        string config_path = AppDirectoryScanner.get_config_path ();
        string new_filename = get_next_local_filename (config_path);
        try {
            key.save_to_file (new_filename);

            var app_info = new DesktopAppInfo.from_filename (new_filename);
            var desktop_app = new DesktopApp (app_info);
            return desktop_app;
        } catch (Error e) {
            throw e;
        }
    }

    public static DesktopApp? create_new_clone_app (DesktopApp app) throws Error {
        string target_filename = app.info.get_filename ();
        string contents;
        try {
            FileUtils.get_contents (target_filename, out contents);
        } catch (FileError e) {
            throw e;
        }

        string config_path = AppDirectoryScanner.get_config_path ();
        string new_filename = get_next_local_filename (config_path);
        var file = File.new_for_path (new_filename);
        try {
            var os = file.create (FileCreateFlags.NONE);
            os.write_all (contents.data, null);
            os.close ();

            var app_info = new DesktopAppInfo.from_filename (new_filename);
            var desktop_app = new DesktopApp (app_info);
            return desktop_app;
        } catch (Error e) {
            throw e;
        }

    }

    public async void save () throws Error {
        var desktop_app = target.desktop_app;

        var key = new KeyFile ();

        string filename = desktop_app.info.get_filename ();

        try {
            key.load_from_file (filename, KeyFileFlags.NONE);
        } catch (Error e) {
            // We do not want to throw an error here
            // since reading existing data is not something fatal
            warning (e.message);
        }

        string lang = Intl.get_language_names ()[0];

        string name = target.save_display_name;

        key.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_TYPE, KeyFileDesktop.TYPE_APPLICATION);
        key.set_locale_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_NAME, lang, name);
        key.set_locale_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_FULLNAME, lang, name);
        key.set_locale_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_COMMENT, lang, target.save_description);
        key.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_ICON, format_desktop_entry_string (target.save_icon));
        key.set_boolean (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_NO_DISPLAY, !target.save_display);
        key.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_EXEC, format_desktop_entry_string (target.save_commandline));
        key.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_PATH, format_desktop_entry_string (target.save_working_path));
        key.set_boolean (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_TERMINAL, target.save_terminal);
        key.set_boolean (KeyFileDesktop.GROUP, DesktopApp.USES_NOTIFICATIONS_KEY, target.uses_notifications);

        string[] save_categories = {};
        foreach (string category in desktop_app.get_categories ()) {
            if (category == "" || category == desktop_app.get_main_category ().id) {
                continue;
            }

            save_categories += category;
        }

        string save_category = target.save_category;
        if (!(save_category in save_categories)) {
            save_categories += save_category;
        }

        key.set_string_list (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_CATEGORIES, save_categories);

        string path = AppDirectoryScanner.get_config_path ();
        string basename = Path.get_basename (filename);

        string new_filename = Path.build_filename (path, basename);
        try {
            string contents = key.to_data ();
            
            var file = File.new_for_path (new_filename);

            if (file.query_exists ()) {
                yield file.replace_contents_async (contents.data, null, false, FileCreateFlags.NONE, null, null);
            } else {
                var stream = yield file.create_async (FileCreateFlags.NONE);
                yield stream.write_all_async (contents.data, Priority.DEFAULT, null, null);
                yield stream.close_async ();
            }

            var new_info = new DesktopAppInfo.from_filename (new_filename);
            if (new_info != null) {
                target.desktop_app.info = new DesktopAppInfo.from_filename (new_filename);
            } else {
                throw new IOError.FAILED (_("Could not load the newly saved file."));
            }
        } catch (Error e) {
            throw e;
        }
    }

    private static string format_desktop_entry_string (string str) {
        return str.escape ();
    }

    private static string get_next_local_filename (string path) {
        uint next_index = get_next_local_app_index (path);
        return Path.build_filename (path, "%s%u%s".printf (DesktopApp.LOCAL_APP_NAME_PREFIX, next_index, DesktopApp.LOCAL_APP_NAME_SUFFIX));
    }

    private static uint get_next_local_app_index (string path) {
        uint index = 1;

        var file = File.new_for_path (path);

        FileInfo? info = null;
        try {
            var enumerator = file.enumerate_children ("standard::*", FileQueryInfoFlags.NONE, null);
            while ((info = enumerator.next_file ()) != null) {
                unowned string name = info.get_name ();
                if (DesktopApp.get_name_only_local (name)) {
                    index++;
                }
            }
        } catch (Error e) {
            warning (e.message);
        }

        return index;
    }
}
