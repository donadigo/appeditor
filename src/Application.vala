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

public class AppEditor.Application : Granite.Application {
    private MainWindow? window = null;

    construct {
        application_id = "com.github.donadigo.appeditor";
        program_name = Constants.APP_NAME;
        app_years = "2016-2017";
        exec_name = Constants.EXEC_NAME;
        app_launcher = Constants.DESKTOP_NAME;

        build_version = Constants.VERSION;
        app_icon = "com.github.donadigo.appeditor";
        main_url = "https://github.com/donadigo/appeditor";
        bug_url = "https://github.com/donadigo/appeditor/issues";
        help_url = "https://github.com/donadigo/appeditor";
        translate_url = "https://github.com/donadigo/appeditor";
        about_authors = {"Adam Bieńkowski <donadigos159gmail.com>", null};
        about_translators = _("translator-credits");

        about_license_type = Gtk.License.GPL_3_0;

        var quit_action = new SimpleAction ("quit", null);
        add_action (quit_action);
        add_accelerator ("<Control>q", "app.quit", null);
        quit_action.activate.connect (() => {
            if (window != null) {
                window.close ();
            }
        });

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
    }
}
