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

public class AppEditor.AppInfoViewStack : Gtk.Stack {
    public signal void view_removed (AppInfoView view);

    construct {
        transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;
        transition_duration = 300;
        interpolate_size = true;

        var no_selected_view = new Granite.Widgets.AlertView (_("No Item Selected"), _("Select an application or start typing to edit one"), "edit-find-symbolic");
        no_selected_view.show_all ();
        add (no_selected_view);

        view_removed.connect (on_view_removed);
    }

    public void show_app_info (DesktopApp desktop_app) {
        AppInfoView? widget = null;

        List<unowned Gtk.Widget> children = get_children ();
        children.@foreach ((child) => {
            if (child is AppInfoView) {
                var app_info_view = (AppInfoView)child;
                if (widget == null && desktop_app.compare (app_info_view.desktop_app)) {
                    widget = app_info_view;
                }
            }
        });

        if (widget == null) {
            widget = new AppInfoView (desktop_app);
            widget.removed.connect (() => view_removed (widget));
            add (widget);
        }

        widget.show_all ();
        visible_child = widget;
    }

    private void on_view_removed (AppInfoView view) {
        remove (view);
    }
}
