#ifndef MODEL_H
#define MODEL_H

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

typedef enum {THE_EMPTY_LIST, BOOLEAN, SYMBOL, FIXNUM,
              CHARACTER, STRING, PAIR, PRIMITIVE_PROC,
              COMPOUND_PROC, INPUT_PORT, OUTPUT_PORT,
              EOF_OBJECT} object_type;

typedef struct object {
    object_type type;
    union {
        struct {
            char value;
        } boolean;
        struct {
            char *value;
        } symbol;
        struct {
            long value;
        } fixnum;
        struct {
            char value;
        } character;
        struct {
            char *value;
        } string;
        struct {
            struct object *car;
            struct object *cdr;
        } pair;
        struct {
            struct object *(*fn)(struct object *arguments);
        } primitive_proc;
        struct {
            struct object *parameters;
            struct object *body;
            struct object *env;
        } compound_proc;
        struct {
            FILE *stream;
        } input_port;
        struct {
            FILE *stream;
        } output_port;
    } data;
} object;

// builtinproc.c
extern object* quote_symbol;
extern object* the_empty_list;
extern object* the_global_environment;
extern object* the_empty_environment;
extern object* true;
extern object* false;
extern object* symbol_table;
extern object* eof_object;
extern object* set_symbol;
extern object* ok_symbol;
extern object* if_symbol;
extern object* else_symbol;
extern object* let_symbol;
extern object* and_symbol;
extern object* or_symbol;
extern object* and_symbol1;
extern object* or_symbol1;
extern object* lambda_symbol;
extern object* begin_symbol;
extern object* cond_symbol;
extern object* define_symbol;

object* cons(object *car, object *cdr);
object* car(object *pair);
object* cdr(object *pair);

#define caar(obj)   car(car(obj))
#define cadr(obj)   car(cdr(obj))
#define cdar(obj)   cdr(car(obj))
#define cddr(obj)   cdr(cdr(obj))
#define caaar(obj)  car(car(car(obj)))
#define caadr(obj)  car(car(cdr(obj)))
#define cadar(obj)  car(cdr(car(obj)))
#define caddr(obj)  car(cdr(cdr(obj)))
#define cdaar(obj)  cdr(car(car(obj)))
#define cdadr(obj)  cdr(car(cdr(obj)))
#define cddar(obj)  cdr(cdr(car(obj)))
#define cdddr(obj)  cdr(cdr(cdr(obj)))
#define caaaar(obj) car(car(car(car(obj))))
#define caaadr(obj) car(car(car(cdr(obj))))
#define caadar(obj) car(car(cdr(car(obj))))
#define caaddr(obj) car(car(cdr(cdr(obj))))
#define cadaar(obj) car(cdr(car(car(obj))))
#define cadadr(obj) car(cdr(car(cdr(obj))))
#define caddar(obj) car(cdr(cdr(car(obj))))
#define cadddr(obj) car(cdr(cdr(cdr(obj))))
#define cdaaar(obj) cdr(car(car(car(obj))))
#define cdaadr(obj) cdr(car(car(cdr(obj))))
#define cdadar(obj) cdr(car(cdr(car(obj))))
#define cdaddr(obj) cdr(car(cdr(cdr(obj))))
#define cddaar(obj) cdr(cdr(car(car(obj))))
#define cddadr(obj) cdr(cdr(car(cdr(obj))))
#define cdddar(obj) cdr(cdr(cdr(car(obj))))
#define cddddr(obj) cdr(cdr(cdr(cdr(obj))))

void set_car(object *obj, object* value);
void set_cdr(object *obj, object* value);

char is_pair(object *obj);
void populate_environment(object *env);

object* apply_proc(object *arguments);
object* make_compound_proc(object *parameters, object *body,
                           object* env);
object* eval_proc(object *arguments);
object* is_null_proc(object *arguments);
object* is_boolean_proc(object *arguments);
object* is_symbol_proc(object *arguments);
object* is_integer_proc(object *arguments);
char is_primitive_proc(object *obj);
char is_compound_proc(object *obj);

void init(void);

// model.c
char is_false(object *obj);
char is_boolean(object *obj);
char is_fixnum(object *obj);
char is_character(object *obj);
char is_string(object *obj);
char is_symbol(object *obj);
char is_the_empty_list(object *obj);
char is_true(object *obj);
char is_input_port(object *obj);
char is_output_port(object *obj);
char is_eof_object(object *obj);


void set_variable_value(object *var, object *val, object *env);
void define_variable(object *var, object *val, object *env);

object* make_character(char value);
object* make_fixnum(long value);
object* make_symbol(char *value);
object* make_string(char *value);
object* extend_environment(object *vars, object *vals,
                           object *base_env);
object* lookup_variable_value(object *var, object *env);
object* alloc_object(void);
object* make_environment(void);
object* make_input_port(FILE *stream);
object* make_output_port(FILE *stream);
object* make_primitive_proc(object *(*fn)(struct object *arguments));
// eval.c

object* first_operand(object *ops);
object* rest_operands(object *ops);
object* list_of_values(object *exps, object *env);
char    is_no_operands(object *ops);
object* eval(object *exp, object *env);

// read.c
object* read(FILE *in);
int peek(FILE *in);

// print.c
void display(FILE *out, object *obj);
void write(FILE *out, object *obj);
// void write_pair(FILE *out, object *pair);

// main
extern int debug;

#endif
