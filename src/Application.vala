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

public class AppEditor.Application : Gtk.Application {
    public const OptionEntry[] OPTIONS = {
        { "create", 'c', 0, OptionArg.FILENAME, out create_exec_filename,
        "Create an application entry from an executable path", "FILENAME" },
        { null }
    };

    public static bool has_gtk_322 () {
        return Gtk.check_version (3, 22, 0) == null;
    }

    private static string? create_exec_filename;

    private MainWindow? window = null;

    construct {
        application_id = "com.github.donadigo.appeditor";
        add_main_option_entries (OPTIONS);

        AppDirectoryScanner.init ();
        var manager = DesktopAppManager.get_default ();
        manager.load ();
    }

    public static int main (string[] args) {
        var app = new Application ();
        return app.run (args);
    }

    public override void activate () {
        if (window == null) {
            window = new MainWindow ();
            add_window (window);
            window.show_all ();
        } else {
            window.present ();
        }

        if (create_exec_filename != null) {
            var file = File.new_for_commandline_arg (create_exec_filename);
            string? basename = file.get_basename ();
            if (!file.query_exists ()) {
                var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                    basename != null ? _("Could not Find \"%s\"").printf (basename) : _("Could not Find Requested File"),
                    _("File <b>\"%s\"</b> does not exist.").printf (file.get_path ()),
                    "dialog-error",
                    Gtk.ButtonsType.CLOSE
                );
    
                message_dialog.run ();
                message_dialog.destroy ();
                return;
            }

            try {
                var new_app = AppInfoViewSaver.create_new_local_app (null, create_exec_filename, basename);
                window.add_app (new_app, true);
            } catch (Error e) {
                var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                    basename != null ? _("Could Not Create a New Application Entry from \"%s\"").printf (basename) :
                                    _("Could Not Create a New Application From Requested File"),
                    e.message,
                    "dialog-error",
                    Gtk.ButtonsType.CLOSE
                );
    
                message_dialog.run ();
                message_dialog.destroy ();
            }
        }
    }
}
