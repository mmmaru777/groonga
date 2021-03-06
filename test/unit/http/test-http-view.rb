# -*- coding: utf-8 -*-
#
# Copyright (C) 2009  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

class HTTPViewTest < Test::Unit::TestCase
  include GroongaHTTPTestUtils

  def setup
    setup_server
  end

  def teardown
    teardown_server
  end

  def test_select
    table_create("softwares", :flags => Table::VIEW)
    table_create("search_engines", :key_type => "ShortText")
    table_create("testing_frameworks", :key_type => "ShortText")

    load("search_engines", [{:_key => "groonga"}, {:_key => "Senna"}])
    load("testing_frameworks", [{:_key => "Cutter"}, {:_key => "test-unit"}])

    assert_select([],
                  [],
                  :table => "softwares",
                  :output_columns => "_key")

    view_add("softwares", "search_engines")
    assert_select([["_key", "Object"]],
                  [["groonga"], ["Senna"]],
                  :table => "softwares",
                  :output_columns => "_key")

    view_add("softwares", "testing_frameworks")
    assert_select([["_key", "Object"]],
                  [["groonga"], ["Senna"], ["Cutter"], ["test-unit"]],
                  :table => "softwares",
                  :output_columns => "_key")
  end

  def test_nonexistent
    table_create("search_engines", :key_type => "ShortText")
    response = get(command_path(:view_add,
                                :view => "nonexistent",
                                :table => "search_engines"))
    assert_error_response(Result::INVALID_ARGUMENT, "invalid view",
                          response,
                          :content_type => "application/json")
  end

  def test_invalid
    table_create("search_engines", :key_type => "ShortText")
    table_create("testing_framework", :key_type => "ShortText")
    response = get(command_path(:view_add,
                                :view => "testing_framework",
                                :table => "search_engines"))
    assert_error_response(Result::INVALID_ARGUMENT, "invalid view",
                          response,
                          :content_type => "application/json")
  end

  def test_add_nonexistent_table
    table_create("softwares", :flags => Table::VIEW)
    response = get(command_path(:view_add,
                                :view => "softwares",
                                :table => "nonexistent"))
    assert_error_response(Result::INVALID_ARGUMENT, "invalid table",
                          response,
                          :content_type => "application/json")
  end

  def test_invalid_table
    table_create("softwares", :flags => Table::VIEW)
    response = get(command_path(:view_add,
                                :view => "softwares",
                                :table => "ShortText"))
    assert_error_response(Result::INVALID_ARGUMENT, "invalid table",
                          response,
                          :content_type => "application/json")
  end
end
