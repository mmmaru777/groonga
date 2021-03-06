%name grn_expr_parser
%token_prefix GRN_EXPR_TOKEN_
%include {
#define assert GRN_ASSERT
}

%token_type { int }

%extra_argument { efs_info *efsi }

%syntax_error {
  {
    grn_ctx *ctx = efsi->ctx;
    grn_obj buf;
    if (ctx->rc == GRN_SUCCESS) {
      GRN_TEXT_INIT(&buf, 0);
      GRN_TEXT_PUT(ctx, &buf, efsi->str, efsi->str_end - efsi->str);
      GRN_TEXT_PUTC(ctx, &buf, '\0');
      ERR(GRN_SYNTAX_ERROR, "Syntax error! (%s)", GRN_TEXT_VALUE(&buf));
      GRN_OBJ_FIN(ctx, &buf);
    }
  }
}

input ::= query.
input ::= expression.

query ::= query_element.
query ::= query query_element. {
  grn_expr_append_op(efsi->ctx, efsi->e, grn_int32_value_at(&efsi->op_stack, -1), 2);
}
query ::= query LOGICAL_AND query_element. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_AND, 2);
}
query ::= query LOGICAL_BUT query_element.{
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_BUT, 2);
}
query ::= query LOGICAL_OR query_element.{
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_OR, 2);
}

query_element ::= QSTRING.
query_element ::= PARENL query PARENR.

query_element ::= RELATIVE_OP query_element.{
  int mode;
  GRN_UINT32_POP(&efsi->mode_stack, mode);
}
query_element ::= IDENTIFIER RELATIVE_OP query_element. {
  int mode;
  grn_obj *c;
  GRN_PTR_POP(&efsi->column_stack, c);
  GRN_UINT32_POP(&efsi->mode_stack, mode);
}
query_element ::= BRACEL expression BRACER. {
  efsi->flags = efsi->default_flags;
}
query_element ::= EVAL primary_expression. {
  efsi->flags = efsi->default_flags;
}

expression ::= assignment_expression.
expression ::= expression COMMA assignment_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_COMMA, 2);
}

assignment_expression ::= conditional_expression.
assignment_expression ::= lefthand_side_expression ASSIGN assignment_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_ASSIGN, 2);
}
assignment_expression ::= lefthand_side_expression STAR_ASSIGN assignment_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_STAR_ASSIGN, 2);
}
assignment_expression ::= lefthand_side_expression SLASH_ASSIGN assignment_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_SLASH_ASSIGN, 2);
}
assignment_expression ::= lefthand_side_expression MOD_ASSIGN assignment_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_MOD_ASSIGN, 2);
}
assignment_expression ::= lefthand_side_expression PLUS_ASSIGN assignment_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_PLUS_ASSIGN, 2);
}
assignment_expression ::= lefthand_side_expression MINUS_ASSIGN assignment_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_MINUS_ASSIGN, 2);
}
assignment_expression ::= lefthand_side_expression SHIFTL_ASSIGN assignment_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_SHIFTL_ASSIGN, 2);
}
assignment_expression ::= lefthand_side_expression SHIFTR_ASSIGN assignment_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_SHIFTR_ASSIGN, 2);
}
assignment_expression ::= lefthand_side_expression SHIFTRR_ASSIGN assignment_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_SHIFTRR_ASSIGN, 2);
}
assignment_expression ::= lefthand_side_expression AND_ASSIGN assignment_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_AND_ASSIGN, 2);
}
assignment_expression ::= lefthand_side_expression XOR_ASSIGN assignment_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_XOR_ASSIGN, 2);
}
assignment_expression ::= lefthand_side_expression OR_ASSIGN assignment_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_OR_ASSIGN, 2);
}

conditional_expression ::= logical_or_expression.
conditional_expression ::= logical_or_expression QUESTION(A) assignment_expression COLON(B) assignment_expression. {
  grn_expr *e = (grn_expr *)efsi->e;
  e->codes[A].nargs = B - A;
  e->codes[B].nargs = e->codes_curr - B - 1;
}

logical_or_expression ::= logical_and_expression.
logical_or_expression ::= logical_or_expression LOGICAL_OR logical_and_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_OR, 2);
}

logical_and_expression ::= bitwise_or_expression.
logical_and_expression ::= logical_and_expression LOGICAL_AND bitwise_or_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_AND, 2);
}
logical_and_expression ::= logical_and_expression LOGICAL_BUT bitwise_or_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_BUT, 2);
}

bitwise_or_expression ::= bitwise_xor_expression.
bitwise_or_expression ::= bitwise_or_expression BITWISE_OR bitwise_xor_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_BITWISE_OR, 2);
}

bitwise_xor_expression ::= bitwise_and_expression.
bitwise_xor_expression ::= bitwise_xor_expression BITWISE_XOR bitwise_and_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_BITWISE_XOR, 2);
}

bitwise_and_expression ::= equality_expression.
bitwise_and_expression ::= bitwise_and_expression BITWISE_AND equality_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_BITWISE_AND, 2);
}

equality_expression ::= relational_expression.
equality_expression ::= equality_expression EQUAL relational_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_EQUAL, 2);
}
equality_expression ::= equality_expression NOT_EQUAL relational_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_NOT_EQUAL, 2);
}

relational_expression ::= shift_expression.
relational_expression ::= relational_expression LESS shift_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_LESS, 2);
}
relational_expression ::= relational_expression GREATER shift_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_GREATER, 2);
}
relational_expression ::= relational_expression LESS_EQUAL shift_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_LESS_EQUAL, 2);
}
relational_expression ::= relational_expression GREATER_EQUAL shift_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_GREATER_EQUAL, 2);
}
relational_expression ::= relational_expression IN shift_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_IN, 2);
}
relational_expression ::= relational_expression MATCH shift_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_MATCH, 2);
}
relational_expression ::= relational_expression NEAR shift_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_NEAR, 2);
}
relational_expression ::= relational_expression NEAR2 shift_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_NEAR2, 2);
}
relational_expression ::= relational_expression SIMILAR shift_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_SIMILAR, 2);
}
relational_expression ::= relational_expression TERM_EXTRACT shift_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_TERM_EXTRACT, 2);
}
relational_expression ::= relational_expression LCP shift_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_LCP, 2);
}
relational_expression ::= relational_expression PREFIX shift_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_PREFIX, 2);
}
relational_expression ::= relational_expression SUFFIX shift_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_SUFFIX, 2);
}

shift_expression ::= additive_expression.
shift_expression ::= shift_expression SHIFTL additive_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_SHIFTL, 2);
}
shift_expression ::= shift_expression SHIFTR additive_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_SHIFTR, 2);
}
shift_expression ::= shift_expression SHIFTRR additive_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_SHIFTRR, 2);
}

additive_expression ::= multiplicative_expression.
additive_expression ::= additive_expression PLUS multiplicative_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_PLUS, 2);
}
additive_expression ::= additive_expression MINUS multiplicative_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_MINUS, 2);
}

multiplicative_expression ::= unary_expression.
multiplicative_expression ::= multiplicative_expression STAR unary_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_STAR, 2);
}
multiplicative_expression ::= multiplicative_expression SLASH unary_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_SLASH, 2);
}
multiplicative_expression ::= multiplicative_expression MOD unary_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_MOD, 2);
}

unary_expression ::= postfix_expression.
unary_expression ::= DELETE unary_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_DELETE, 1);
}
unary_expression ::= INCR unary_expression. {
  grn_ctx *ctx = efsi->ctx;
  grn_expr *e = (grn_expr *)(efsi->e);
  grn_expr_dfi *dfi_;
  unsigned int const_p;

  DFI_POP(e, dfi_);
  const_p = CONSTP(dfi_->code->value);
  DFI_PUT(e, dfi_->type, dfi_->domain, dfi_->code);
  if (const_p) {
    ERR(GRN_SYNTAX_ERROR,
        "constant can't be incremented (%.*s)",
        (int)(efsi->str_end - efsi->str), efsi->str);
  } else {
    grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_INCR, 1);
  }
}
unary_expression ::= DECR unary_expression. {
  grn_ctx *ctx = efsi->ctx;
  grn_expr *e = (grn_expr *)(efsi->e);
  grn_expr_dfi *dfi_;
  unsigned int const_p;

  DFI_POP(e, dfi_);
  const_p = CONSTP(dfi_->code->value);
  DFI_PUT(e, dfi_->type, dfi_->domain, dfi_->code);
  if (const_p) {
    ERR(GRN_SYNTAX_ERROR,
        "constant can't be decremented (%.*s)",
        (int)(efsi->str_end - efsi->str), efsi->str);
  } else {
    grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_DECR, 1);
  }
}
unary_expression ::= PLUS unary_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_PLUS, 1);
}
unary_expression ::= MINUS unary_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_MINUS, 1);
}
unary_expression ::= NOT unary_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_NOT, 1);
}
unary_expression ::= BITWISE_NOT unary_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_BITWISE_NOT, 1);
}
unary_expression ::= ADJUST unary_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_ADJUST, 1);
}
unary_expression ::= EXACT unary_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_EXACT, 1);
}
unary_expression ::= PARTIAL unary_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_PARTIAL, 1);
}
unary_expression ::= UNSPLIT unary_expression. {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_UNSPLIT, 1);
}

postfix_expression ::= lefthand_side_expression.
postfix_expression ::= lefthand_side_expression INCR. {
  grn_ctx *ctx = efsi->ctx;
  grn_expr *e = (grn_expr *)(efsi->e);
  grn_expr_dfi *dfi_;
  unsigned int const_p;

  DFI_POP(e, dfi_);
  const_p = CONSTP(dfi_->code->value);
  DFI_PUT(e, dfi_->type, dfi_->domain, dfi_->code);
  if (const_p) {
    ERR(GRN_SYNTAX_ERROR,
        "constant can't be incremented (%.*s)",
        (int)(efsi->str_end - efsi->str), efsi->str);
  } else {
    grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_INCR_POST, 1);
  }
}
postfix_expression ::= lefthand_side_expression DECR. {
  grn_ctx *ctx = efsi->ctx;
  grn_expr *e = (grn_expr *)(efsi->e);
  grn_expr_dfi *dfi_;
  unsigned int const_p;

  DFI_POP(e, dfi_);
  const_p = CONSTP(dfi_->code->value);
  DFI_PUT(e, dfi_->type, dfi_->domain, dfi_->code);
  if (const_p) {
    ERR(GRN_SYNTAX_ERROR,
        "constant can't be decremented (%.*s)",
        (int)(efsi->str_end - efsi->str), efsi->str);
  } else {
    grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_DECR_POST, 1);
  }
}

lefthand_side_expression ::= call_expression.
lefthand_side_expression ::= member_expression.

call_expression ::= member_expression arguments(A). {
  grn_expr_append_op(efsi->ctx, efsi->e, GRN_OP_CALL, A);
}

member_expression ::= primary_expression.
member_expression ::= member_expression member_expression_part.

primary_expression ::= object_literal.
primary_expression ::= PARENL expression PARENR.
primary_expression ::= IDENTIFIER.
primary_expression ::= array_literal.
primary_expression ::= DECIMAL.
primary_expression ::= HEX_INTEGER.
primary_expression ::= STRING.
primary_expression ::= BOOLEAN.
primary_expression ::= NULL.

array_literal ::= BRACKETL elision BRACKETR.
array_literal ::= BRACKETL element_list elision BRACKETR.
array_literal ::= BRACKETL element_list BRACKETR.

elision ::= COMMA.
elision ::= elision COMMA.

element_list ::= assignment_expression.
element_list ::= elision assignment_expression.
element_list ::= element_list elision assignment_expression.

object_literal ::= BRACEL property_name_and_value_list BRACER.

property_name_and_value_list ::= .
property_name_and_value_list ::= property_name_and_value_list COMMA property_name_and_value.

property_name_and_value ::= property_name COLON assignment_expression.
property_name ::= IDENTIFIER|STRING|DECIMAL.

member_expression_part ::= BRACKETL expression BRACKETR.
member_expression_part ::= DOT IDENTIFIER.

arguments(A) ::= PARENL argument_list(B) PARENR. { A = B; }
argument_list(A) ::= . { A = 0; }
argument_list(A) ::= assignment_expression. { A = 1; }
argument_list(A) ::= argument_list(B) COMMA assignment_expression. { A = B + 1; }
