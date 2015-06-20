/* Last modified Time-stamp: <2015-06-20 19:48:52 s>
 * @(#)builtinproc.c
 */

#include "model.h"
#include <string.h>

object *the_empty_list = NULL;
object *false = NULL;
object *true = NULL;
object *symbol_table = NULL;
object *quote_symbol = NULL;
object *define_symbol = NULL;
object *set_symbol = NULL;
object *ok_symbol = NULL;
object *if_symbol = NULL;
object *lambda_symbol = NULL;
object *begin_symbol = NULL;
object *cond_symbol = NULL;
object *else_symbol = NULL;
object *let_symbol = NULL;
object *and_symbol = NULL;
object *or_symbol = NULL;
object *and_symbol1 = NULL;
object *or_symbol1 = NULL;
object *eof_object = NULL;
object *the_empty_environment = NULL;
object *the_global_environment = NULL;

object *cons(object *car, object *cdr) {
    object *obj;

    obj = alloc_object();
    obj->type = PAIR;
    assert(NULL != car);
    assert(NULL != cdr);
    obj->data.pair.car = car;
    obj->data.pair.cdr = cdr;
    return obj;
}

char is_pair(object *obj) {
    return obj->type == PAIR;
}

object *car(object *pair) {

  assert(pair->type == PAIR);

  if (pair->type == PAIR)
    return pair->data.pair.car;
  else
  {
      fprintf(stderr, "is not pair\n");
      //return read(stdin);
      exit(0);
  }

}

void set_car(object *obj, object* value) {
    obj->data.pair.car = value;
}

object *cdr(object *pair) {
    return pair->data.pair.cdr;
}

void set_cdr(object *obj, object* value) {
    obj->data.pair.cdr = value;
}

char is_primitive_proc(object *obj) {
    return obj->type == PRIMITIVE_PROC;
}

object *is_null_proc(object *arguments) {
    return is_the_empty_list(car(arguments)) ? true : false;
}

object *is_boolean_proc(object *arguments) {
    return is_boolean(car(arguments)) ? true : false;
}

object *is_symbol_proc(object *arguments) {
    return is_symbol(car(arguments)) ? true : false;
}

object *is_integer_proc(object *arguments) {
    return is_fixnum(car(arguments)) ? true : false;
}

object *is_char_proc(object *arguments) {
    return is_character(car(arguments)) ? true : false;
}

object *is_string_proc(object *arguments) {
    return is_string(car(arguments)) ? true : false;
}

object *is_pair_proc(object *arguments) {
    return is_pair(car(arguments)) ? true : false;
}

char is_compound_proc(object *obj);

object *is_procedure_proc(object *arguments) {
    object *obj;

    obj = car(arguments);
    return (is_primitive_proc(obj) ||
            is_compound_proc(obj)) ?
                true :
                false;
}

object *char_to_integer_proc(object *arguments) {
    return make_fixnum((car(arguments))->data.character.value);
}

object *integer_to_char_proc(object *arguments) {
    return make_character((car(arguments))->data.fixnum.value);
}

char* itoa(int val, int base){

	static char buf[32] = {0};

	int i = 30;
        if (val)
          for(; val && i ; --i, val /= base)
            buf[i] = "0123456789abcdef"[val % base];
        else
            buf[i--] = '0';

	return &buf[i+1];
}

object *number_to_string_proc(object *arguments) {
    int base = (cadr(arguments))->data.fixnum.value;
    return make_string( itoa((car(arguments))->data.fixnum.value, base) );
}

object *string_to_number_proc(object *arguments) {
    return make_fixnum(atoi((car(arguments))->data.string.value));
}

object *symbol_to_string_proc(object *arguments) {
    return make_string((car(arguments))->data.symbol.value);
}

object *string_to_symbol_proc(object *arguments) {
    return make_symbol((car(arguments))->data.string.value);
}

object *add_proc(object *arguments) {
    long result = 0;

    while (!is_the_empty_list(arguments)) {
        result += (car(arguments))->data.fixnum.value;
        arguments = cdr(arguments);
    }
    return make_fixnum(result);
}

object *sub_proc(object *arguments) {
    long result;

    result = (car(arguments))->data.fixnum.value;
    while (!is_the_empty_list(arguments = cdr(arguments))) {
        result -= (car(arguments))->data.fixnum.value;
    }
    return make_fixnum(result);
}

object *mul_proc(object *arguments) {
    long result = 1;

    while (!is_the_empty_list(arguments)) {
        result *= (car(arguments))->data.fixnum.value;
        arguments = cdr(arguments);
    }
    return make_fixnum(result);
}

object *quotient_proc(object *arguments) {
    return make_fixnum(
        ((car(arguments) )->data.fixnum.value)/
        ((cadr(arguments))->data.fixnum.value));
}

object *remainder_proc(object *arguments) {
    return make_fixnum(
        ((car(arguments) )->data.fixnum.value)%
        ((cadr(arguments))->data.fixnum.value));
}

object *modulo_proc(object *arguments) {
    int ret =
        ((car(arguments) )->data.fixnum.value) %
        ((cadr(arguments))->data.fixnum.value);
    if (ret < 0) ret += ((cadr(arguments))->data.fixnum.value);
    return make_fixnum( ret );
}

object *is_number_equal_proc(object *arguments) {
    long value;

    value = (car(arguments))->data.fixnum.value;
    while (!is_the_empty_list(arguments = cdr(arguments))) {
        if (value != ((car(arguments))->data.fixnum.value)) {
            return false;
        }
    }
    return true;
}

object *is_less_than_proc(object *arguments) {
    long previous;
    long next;

    previous = (car(arguments))->data.fixnum.value;
    while (!is_the_empty_list(arguments = cdr(arguments))) {
        next = (car(arguments))->data.fixnum.value;
        if (previous < next) {
            previous = next;
        }
        else {
            return false;
        }
    }
    return true;
}

object *is_greater_than_proc(object *arguments) {
    long previous;
    long next;

    previous = (car(arguments))->data.fixnum.value;
    while (!is_the_empty_list(arguments = cdr(arguments))) {
        next = (car(arguments))->data.fixnum.value;
        if (previous > next) {
            previous = next;
        }
        else {
            return false;
        }
    }
    return true;
}

object *cons_proc(object *arguments) {
    return cons(car(arguments), cadr(arguments));
}

object *car_proc(object *arguments) {
    return caar(arguments);
}

object *cdr_proc(object *arguments) {
    return cdar(arguments);
}

object *set_car_proc(object *arguments) {
    set_car(car(arguments), cadr(arguments));
    return ok_symbol;
}

object *set_cdr_proc(object *arguments) {
    set_cdr(car(arguments), cadr(arguments));
    return ok_symbol;
}

object *list_proc(object *arguments) {
    return arguments;
}

object *is_eq_proc(object *arguments) {
    object *obj1 = NULL;
    object *obj2 = NULL;

    obj1 = car(arguments);
    obj2 = cadr(arguments);

    if (obj1->type != obj2->type) {
        return false;
    }
    switch (obj1->type) {
        case FIXNUM:
            return (obj1->data.fixnum.value ==
                    obj2->data.fixnum.value) ?
                        true : false;
            break;
        case CHARACTER:
            return (obj1->data.character.value ==
                    obj2->data.character.value) ?
                        true : false;
            break;
        case STRING:
            return (strcmp(obj1->data.string.value,
                           obj2->data.string.value) == 0) ?
                        true : false;
            break;
        default:
            return (obj1 == obj2) ? true : false;
    }
}
/*
object *is_eqv_pair_internal(object *arguments) {
      object *car_obj1 = NULL;
      object *cdr_obj1 = NULL;
      object *car_obj2 = NULL;
      object *cdr_obj2 = NULL;

      car_obj1 = car(obj1);
      car_obj2 = car(obj2);
      cdr_obj1 = cdr(obj1);
      cdr_obj2 = cdr(obj2);


      return is_eqv_proc(car_obj1, car_obj2) &&
        is_eqv_proc(cdr_obj1, cdr_obj1);
}
*/

object *is_eqv_proc(object *arguments) {
  object *obj1 = NULL;
  object *obj2 = NULL;

  obj1 = car(arguments);
  obj2 = cadr(arguments);

  if (obj1->type != obj2->type) {
    return false;
  }
  switch (obj1->type) {
  case FIXNUM:
    return (obj1->data.fixnum.value ==
            obj2->data.fixnum.value) ?
      true : false;
    break;
  case CHARACTER:
    return (obj1->data.character.value ==
            obj2->data.character.value) ?
      true : false;
    break;
  case STRING:
    return (strcmp(obj1->data.string.value,
                   obj2->data.string.value) == 0) ?
      true : false;
    break;
  case SYMBOL:
    return (strcmp(obj1->data.symbol.value,
                   obj2->data.symbol.value) == 0) ?
      true : false;
    break;
  default:
    return (obj1 == obj2) ? true : false;
  }
}

object *apply_proc(object *arguments) {
    fprintf(stderr, "illegal state: The body of the apply "
            "primitive procedure should not execute.\n");
    exit(1);
}

object *interaction_environment_proc(object *arguments) {
    return the_global_environment;
}

object *setup_environment(void);

object *null_environment_proc(object *arguments) {
    return setup_environment();
}

object *environment_proc(object *arguments) {
    return make_environment();
}

object *eval_proc(object *arguments) {
    fprintf(stderr, "illegal state: The body of the eval "
            "primitive procedure should not execute.\n");
    exit(1);
}

object *load_proc(object *arguments) {
    char *filename;
    FILE *in;
    object *exp;
    object *result;

    filename = car(arguments)->data.string.value;
    in = fopen(filename, "r");
    if (in == NULL) {
        fprintf(stderr, "could not load file \"%s\"", filename);
        exit(1);
    }
    while ((exp = read(in)) != NULL) {
        result = eval(exp, the_global_environment);
    }
    fclose(in);
    return result;
}

object *open_input_port_proc(object *arguments) {
    char *filename;
    FILE *in;

    filename = car(arguments)->data.string.value;
    in = fopen(filename, "r");
    if (in == NULL) {
        fprintf(stderr, "could not open file \"%s\"\n", filename);
        exit(1);
    }
    return make_input_port(in);
}

object *close_input_port_proc(object *arguments) {
    int result;

    result = fclose(car(arguments)->data.input_port.stream);
    if (result == EOF) {
        fprintf(stderr, "could not close input port\n");
        exit(1);
    }
    return ok_symbol;
}

object *is_input_port_proc(object *arguments) {
    return is_input_port(car(arguments)) ? true : false;
}

object *read_proc(object *arguments) {
    FILE *in;
    object *result;

    in = is_the_empty_list(arguments) ?
             stdin :
             car(arguments)->data.input_port.stream;
    result = read(in);
    return (result == NULL) ? eof_object : result;
}

object *read_char_proc(object *arguments) {
    FILE *in;
    int result;

    in = is_the_empty_list(arguments) ?
             stdin :
             car(arguments)->data.input_port.stream;
    result = getc(in);
    return (result == EOF) ? eof_object : make_character(result);
}

object *read_byte_proc(object *arguments) {
    FILE *in;
    int result;

    in = is_the_empty_list(arguments) ?
             stdout :
             car(arguments)->data.output_port.stream;
    fread(&result, 1, sizeof(char), in);
    if (feof(in) || ferror(in))
    {
        clearerr(in);
        return eof_object;
    }
    return make_fixnum(result);
}

object *peek_char_proc(object *arguments) {
    FILE *in;
    int result;

    in = is_the_empty_list(arguments) ?
             stdin :
             car(arguments)->data.input_port.stream;
    result = peek(in);
    return (result == EOF) ? eof_object : make_character(result);
}

object *is_eof_object_proc(object *arguments) {
    return is_eof_object(car(arguments)) ? true : false;
}

object *open_output_port_proc(object *arguments) {
    char *filename;
    FILE *out;

    filename = car(arguments)->data.string.value;
    out = fopen(filename, "w");
    if (out == NULL) {
        fprintf(stderr, "could not open file \"%s\"\n", filename);
        exit(1);
    }
    return make_output_port(out);
}

object *close_output_port_proc(object *arguments) {
    int result;

    result = fclose(car(arguments)->data.output_port.stream);
    if (result == EOF) {
        fprintf(stderr, "could not close output port\n");
        exit(1);
    }
    return ok_symbol;
}

object *is_output_port_proc(object *arguments) {
    return is_output_port(car(arguments)) ? true : false;
}

object *write_char_proc(object *arguments) {
    object *character;
    FILE *out;

    character = car(arguments);
    arguments = cdr(arguments);
    out = is_the_empty_list(arguments) ?
             stdout :
             car(arguments)->data.output_port.stream;
    putc(character->data.character.value, out);
    fflush(out);
    return ok_symbol;
}

object *write_byte_proc(object *arguments) {
    object *integer;
    FILE *out;
    size_t ret;

    integer   = car(arguments);
    arguments = cdr(arguments);
    out = is_the_empty_list(arguments) ?
             stdout :
             car(arguments)->data.output_port.stream;
    ret = fwrite(&integer->data.fixnum.value, 1, sizeof(char), out);
    if (ret < 1)
    {
        fprintf(stderr, "could not write the byte.\n");
        exit(1);
    }
    fflush(out);
    return ok_symbol;
}

object *write_proc(object *arguments) {
    object *exp;
    FILE *out;

    exp = car(arguments);
    arguments = cdr(arguments);
    out = is_the_empty_list(arguments) ?
             stdout :
             car(arguments)->data.output_port.stream;
    write(out, exp);
    fflush(out);
    return ok_symbol;
}

object *display_proc(object *arguments) {
    object *exp;
    FILE *out;

    exp = car(arguments);
    arguments = cdr(arguments);
    out = is_the_empty_list(arguments) ?
             stdout :
             car(arguments)->data.output_port.stream;
    display(out, exp);
    fflush(out);
    return ok_symbol;
}

object *error_proc(object *arguments) {
    while (!is_the_empty_list(arguments)) {
        write(stderr, car(arguments));
        fprintf(stderr, " ");
        arguments = cdr(arguments);
    };
    printf("\nexiting\n");
    exit(1);
}

object *bit_and_proc(object *arguments) {
  object *obj1 = NULL;
  object *obj2 = NULL;

  obj1 = car(arguments);
  obj2 = cadr(arguments);

  if (debug)
  {
    printf("\n%s: ", __FUNCTION__);
    write (stdout, arguments);
    printf("\n");
  }
  if (FIXNUM != obj1->type ||
      FIXNUM != obj2->type) {
    assert(0);
    printf("\narguments are not numbers\n");
    exit(1);
  }

  return make_fixnum(obj1->data.fixnum.value & obj2->data.fixnum.value);
}

object *bit_or_proc(object *arguments) {
  object *obj1 = NULL;
  object *obj2 = NULL;

  obj1 = car(arguments);
  obj2 = cadr(arguments);

  if (debug)
  {
      printf("\n%s: ", __FUNCTION__);
      write (stdout, arguments);
      printf("\n");
  }
  if (FIXNUM != obj1->type ||
      FIXNUM != obj2->type) {
      printf("\narguments are not numbers\n");
      exit(1);
  }

  return make_fixnum(obj1->data.fixnum.value | obj2->data.fixnum.value);
}

object *bit_xor_proc(object *arguments) {
  object *obj1 = NULL;
  object *obj2 = NULL;

  obj1 = car(arguments);
  obj2 = cadr(arguments);

  if (debug)
  {
      printf("\n%s: ", __FUNCTION__);
      write (stdout, arguments);
      printf("\n");
  }
  if (FIXNUM != obj1->type ||
      FIXNUM != obj2->type) {
      printf("\narguments are not numbers\n");
      exit(1);
  }

  return make_fixnum(obj1->data.fixnum.value ^ obj2->data.fixnum.value);
}

object *bit_inverse_proc(object *arguments) {
  object *obj1 = NULL;

  obj1 = car(arguments);

  if (debug)
  {
      printf("\n%s: ", __FUNCTION__);
      write (stdout, arguments);
      printf("\n");
  }
  if (FIXNUM != obj1->type) {
      printf("\narguments are not numbers\n");
      exit(1);
  }

  return make_fixnum(~(obj1->data.fixnum.value));
}

/*
object *bit_quotient_proc(object *arguments) {
  object *obj1 = NULL;
  object *obj2 = NULL;

  obj1 = car(arguments);
  obj2 = cadr(arguments);

  if (debug)
  {
      printf("\n%s: ", __FUNCTION__);
      write (stdout, arguments);
      printf("\n");
  }
  if (FIXNUM != obj1->type ||
      FIXNUM != obj2->type) {
      printf("\narguments are not numbers\n");
      exit(1);
  }

  return make_fixnum(obj1->data.fixnum.value / obj2->data.fixnum.value);
}
*/

object *make_compound_proc(object *parameters, object *body,
                           object* env) {
    object *obj;

    obj = alloc_object();
    obj->type = COMPOUND_PROC;
    obj->data.compound_proc.parameters = parameters;
    obj->data.compound_proc.body = body;
    obj->data.compound_proc.env = env;
    return obj;
}

char is_compound_proc(object *obj) {
    return obj->type == COMPOUND_PROC;
}

object *string_length_proc(object *arguments) {
    object *string;

    string = car(arguments);

    if (string->type != STRING)
    {
        fprintf(stderr, "arg is not string\n");
        exit(0);
    }

    return make_fixnum(strlen(string->data.string.value));
}


void populate_environment(object *env) {

#define add_procedure(scheme_name, c_name)              \
    define_variable(make_symbol(scheme_name),           \
                    make_primitive_proc(c_name),        \
                    env);

    add_procedure("null?"      , is_null_proc);
    add_procedure("boolean?"   , is_boolean_proc);
    add_procedure("symbol?"    , is_symbol_proc);
    add_procedure("integer?"   , is_integer_proc);
    add_procedure("char?"      , is_char_proc);
    add_procedure("string?"    , is_string_proc);
    add_procedure("pair?"      , is_pair_proc);
    add_procedure("procedure?" , is_procedure_proc);

    add_procedure("char->integer" , char_to_integer_proc);
    add_procedure("integer->char" , integer_to_char_proc);
    add_procedure("number->string", number_to_string_proc);
    add_procedure("string->number", string_to_number_proc);
    add_procedure("symbol->string", symbol_to_string_proc);
    add_procedure("string->symbol", string_to_symbol_proc);

    add_procedure("+"        , add_proc);
    add_procedure("-"        , sub_proc);
    add_procedure("*"        , mul_proc);
    add_procedure("quotient" , quotient_proc);
    add_procedure("remainder", remainder_proc);
    add_procedure("modulo"   , modulo_proc);
    add_procedure("="        , is_number_equal_proc);
    add_procedure("<"        , is_less_than_proc);
    add_procedure(">"        , is_greater_than_proc);

    add_procedure("cons"    , cons_proc);
    add_procedure("car"     , car_proc);
    add_procedure("cdr"     , cdr_proc);
    add_procedure("set-car!", set_car_proc);
    add_procedure("set-cdr!", set_cdr_proc);
    add_procedure("list"    , list_proc);

    add_procedure("eq?", is_eq_proc);
    add_procedure("eqv?", is_eqv_proc);


    add_procedure("apply", apply_proc);

    add_procedure("interaction-environment",
                                     interaction_environment_proc);
    add_procedure("null-environment", null_environment_proc);
    add_procedure("environment"     , environment_proc);
    add_procedure("eval"            , eval_proc);

    add_procedure("load"             , load_proc);
    add_procedure("open-input-port"  , open_input_port_proc);
    add_procedure("close-input-port" , close_input_port_proc);
    add_procedure("input-port?"      , is_input_port_proc);
    add_procedure("read"             , read_proc);
    add_procedure("read-char"        , read_char_proc);
    add_procedure("read-byte"        , read_byte_proc);
    add_procedure("peek-char"        , peek_char_proc);
    add_procedure("eof-object?"      , is_eof_object_proc);
    add_procedure("open-output-port" , open_output_port_proc);
    add_procedure("close-output-port", close_output_port_proc);
    add_procedure("output-port?"     , is_output_port_proc);
    add_procedure("write"            , write_proc);
    add_procedure("write-char"       , write_char_proc);
    add_procedure("write-byte"       , write_byte_proc);
    add_procedure("display"          , display_proc);

    add_procedure("error", error_proc);

    add_procedure("&", bit_and_proc);
    add_procedure("|", bit_or_proc);
    add_procedure("^", bit_xor_proc);
    add_procedure("~", bit_inverse_proc);
    add_procedure("string-length", string_length_proc);
    // add_procedure("quotient", bit_quotient_proc);

}

void init(void) {
    the_empty_list = alloc_object();
    the_empty_list->type = THE_EMPTY_LIST;

    false = alloc_object();
    false->type = BOOLEAN;
    false->data.boolean.value = 0;

    true = alloc_object();
    true->type = BOOLEAN;
    true->data.boolean.value = 1;

    symbol_table = the_empty_list;
    quote_symbol = make_symbol("quote");
    define_symbol = make_symbol("define");
    set_symbol = make_symbol("set!");
    ok_symbol = make_symbol("ok");
    if_symbol = make_symbol("if");
    lambda_symbol = make_symbol("lambda");
    begin_symbol = make_symbol("begin");
    cond_symbol = make_symbol("cond");
    else_symbol = make_symbol("else");
    let_symbol = make_symbol("let");
    // TODO
    and_symbol = make_symbol("and");
    or_symbol = make_symbol("or");
    and_symbol1 = make_symbol("&&");
    or_symbol1 = make_symbol("||");

    eof_object = alloc_object();
    eof_object->type = EOF_OBJECT;

    the_empty_environment = the_empty_list;

    the_global_environment = make_environment();
}
