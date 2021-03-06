/* -*- c-basic-offset: 2; coding: utf-8 -*- */
/*
  Copyright (C) 2010-2011  Kouhei Sutou <kou@clear-code.com>

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License version 2.1 as published by the Free Software Foundation.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/

#include <groonga.h>

#include <gcutter.h>
#include <glib/gstdio.h>

#include "../lib/grn-assertions.h"

void data_table(void);
void test_table(gpointer data);

static grn_logger_info *logger;
static grn_ctx *context;
static grn_obj *database;

void
cut_setup(void)
{
  context = NULL;

  logger = setup_grn_logger();

  context = g_new0(grn_ctx, 1);
  grn_ctx_init(context, 0);

  database = grn_db_create(context, NULL, NULL);
}

void
cut_teardown(void)
{
  grn_obj_close(context, database);
  grn_ctx_fin(context);
  g_free(context);

  teardown_grn_logger(logger);
}

void
data_table(void)
{
#define ADD_DATA(label, flags)                                          \
  cut_add_data(label, GINT_TO_POINTER(flags), NULL, NULL)

  ADD_DATA("no-key", GRN_OBJ_TABLE_NO_KEY);
  ADD_DATA("hash", GRN_OBJ_TABLE_HASH_KEY);
  ADD_DATA("patricia trie", GRN_OBJ_TABLE_PAT_KEY);

#undef ADD_DATA
}

void
test_table(gpointer data)
{
  grn_obj *table;
  grn_obj_flags flags = GPOINTER_TO_INT(data);
  grn_table_cursor *cursor;

  table = grn_table_create(context, NULL, 0, NULL,
                           flags,
                           get_object("ShortText"),
                           NULL);
  cursor = grn_table_cursor_open(context, table, NULL, 0, NULL, 0, 0, -1, 0);
  /* FIXME: grn_test_assert_equal_object() */
  cut_assert_equal_pointer(table, grn_table_cursor_table(context, cursor));
}
