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

public class AppEditor.PersistentPlaceholderEntry : Gtk.Entry {
    public override bool draw (Cairo.Context ctx) {
        base.draw (ctx);

        if (text == "" && has_focus) {
            var color = get_placeholder_text_color ();
            var attr = Pango.attr_foreground_new (color.red, color.green, color.blue);
            attr.start_index = 0;
            attr.end_index = int.MAX;

            var attr_list = new Pango.AttrList ();
            attr_list.insert (attr.copy ());

            var layout = create_pango_layout (placeholder_text);
            layout.set_attributes (attr_list);

            int x, y;
            get_layout_offsets (out x, out y);

            ctx.move_to (x, y);
            Pango.cairo_show_layout (ctx, layout);
        }

        return true;
    }

    private Pango.Color get_placeholder_text_color () {
        Gdk.RGBA fg = { 0.5, 0.5, 0.5 };
        get_style_context ().lookup_color ("placeholder_text_color", out fg);

        Pango.Color color = {};
        color.red = (uint16)(fg.red * 65535 + 0.5).clamp (0, 65535);
        color.green = (uint16)(fg.green * 65535 + 0.5).clamp (0, 65535);
        color.blue = (uint16)(fg.blue * 65535 + 0.5).clamp (0, 65535);
        return color;
    }
}
