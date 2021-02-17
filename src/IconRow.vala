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

public class AppEditor.IconRow : Gtk.ListBoxRow {
    public string icon_name { get; construct; }

    construct {
        var image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.LARGE_TOOLBAR);
        image.pixel_size = 24;

        var label = new Gtk.Label (icon_name);

        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.column_spacing = 12;
        grid.attach (image, 0, 0, 1, 1);
        grid.attach (label, 1, 0, 1, 1);
        
        add (grid);
    }

    public IconRow (string icon_name) {
        Object (icon_name: icon_name);
    }
}
