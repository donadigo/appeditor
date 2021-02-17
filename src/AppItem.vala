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

public class AppEditor.AppItem : Granite.Widgets.SourceList.Item {
    public DesktopApp desktop_app { get; construct; }

    construct {
        desktop_app.changed.connect (reload);
        reload ();
    }

    public AppItem (DesktopApp desktop_app) {
        Object (desktop_app: desktop_app);
    }

    private void reload () {
        unowned string display_name = desktop_app.get_display_name ();
        if (display_name.strip () == "") {
            display_name = _("Unknown");
        }

        name = display_name;
        icon = desktop_app.get_icon ();
    }
}
