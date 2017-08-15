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

public class AppEditor.AppDirectoryScanner : Object {
    private const string APPLICATIONS_DIRECTORY = "applications";

    private static string[] app_directories;
    private static string? config_path;

    public static void init () {
        config_path = append_directory (Environment.get_user_data_dir ());
        if (config_path == null) {
            config_path = Path.build_filename (Environment.get_home_dir (), ".local", "share", APPLICATIONS_DIRECTORY);
        }

        foreach (unowned string data_dir in Environment.get_system_data_dirs ()) {
            append_directory (data_dir);
        }
    }

    public static string get_config_path () {
        return config_path;
    }

    public static int get_desktop_id_count (string desktop_id) {
        int count = 0;
        foreach (string directory in app_directories) {
            string filename = Path.build_filename (directory, desktop_id);
            if (FileUtils.test (filename, FileTest.EXISTS)) {
                count++;
            }
        }

        return count;
    }

    private static string? append_directory (string directory) {
        string apps_dir = Path.build_filename (directory, APPLICATIONS_DIRECTORY);
        if (FileUtils.test (apps_dir, FileTest.EXISTS)) {
            app_directories += apps_dir;
        }

        return apps_dir;
    }
}