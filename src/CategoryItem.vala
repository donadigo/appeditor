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

public class AppEditor.CategoryItem : Granite.Widgets.SourceList.ExpandableItem, Granite.Widgets.SourceListSortable {
    public AppCategory category { get; construct; }

    public CategoryItem (AppCategory category) {
        Object (
            category: category,
            name: category.name
        );
    }

    public bool allow_dnd_sorting () {
        return false;
    }

    public int compare (Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b) {
        return strcmp (a.name, b.name);
    }
}
