
#include "model.h"

/* no GC so truely "unlimited extent" */
object *alloc_object(void) {
    object *obj;

    obj = malloc(sizeof(object));
    if (obj == NULL) {
        fprintf(stderr, "out of memory\n");
        exit(1);
    }
    return obj;
}

char is_the_empty_list(object *obj) {
    return obj == the_empty_list;
}

char is_boolean(object *obj) {
    return obj->type == BOOLEAN;
}

char is_false(object *obj) {
    return obj == false;
}

char is_true(object *obj) {
    return !is_false(obj);
}

object *make_symbol(char *value) {
    object *obj;
    object *element;

    /* search for they symbol in the symbol table */
    element = symbol_table;
    while (!is_the_empty_list(element)) {
        if (strcmp(car(element)->data.symbol.value, value) == 0) {
            return car(element);
        }
        element = cdr(element);
    };

    /* create the symbol and add it to the symbol table */
    obj = alloc_object();
    obj->type = SYMBOL;
    obj->data.symbol.value = malloc(strlen(value) + 1);
    if (obj->data.symbol.value == NULL) {
        fprintf(stderr, "out of memory\n");
        exit(1);
    }
    strcpy(obj->data.symbol.value, value);
    symbol_table = cons(obj, symbol_table);
    return obj;
}

object *make_primitive_proc(
           object *(*fn)(struct object *arguments)) {
    object *obj;

    obj = alloc_object();
    obj->type = PRIMITIVE_PROC;
    obj->data.primitive_proc.fn = fn;
    return obj;
}

char is_symbol(object *obj) {
    return obj->type == SYMBOL;
}

object *make_fixnum(long value) {
    object *obj;

    obj = alloc_object();
    obj->type = FIXNUM;
    obj->data.fixnum.value = value;
    return obj;
}

char is_fixnum(object *obj) {
    return obj->type == FIXNUM;
}

object *make_character(char value) {
    object *obj;

    obj = alloc_object();
    obj->type = CHARACTER;
    obj->data.character.value = value;
    return obj;
}

char is_character(object *obj) {
    return obj->type == CHARACTER;
}

object *make_string(char *value) {
    object *obj;

    obj = alloc_object();
    obj->type = STRING;
    obj->data.string.value = malloc(strlen(value) + 1);
    if (obj->data.string.value == NULL) {
        fprintf(stderr, "out of memory\n");
        exit(1);
    }
    strcpy(obj->data.string.value, value);
    return obj;
}

char is_string(object *obj) {
    return obj->type == STRING;
}

object *make_input_port(FILE *stream) {
    object *obj;

    obj = alloc_object();
    obj->type = INPUT_PORT;
    obj->data.input_port.stream = stream;
    return obj;
}

char is_input_port(object *obj) {
    return obj->type == INPUT_PORT;
}

object *make_output_port(FILE *stream) {
    object *obj;

    obj = alloc_object();
    obj->type = OUTPUT_PORT;
    obj->data.output_port.stream = stream;
    return obj;
}

char is_output_port(object *obj) {
    return obj->type == OUTPUT_PORT;
}

char is_eof_object(object *obj) {
    return obj == eof_object;
}

object *enclosing_environment(object *env) {
    return cdr(env);
}

object *first_frame(object *env) {
    return car(env);
}

object *make_frame(object *variables, object *values) {
    if (debug)
    {
        printf("\n---vars\n");   write(stdout, variables);
        printf("\n---values\n"); write(stdout, values);
        printf("\n---cons\n");   write(stdout, cons(variables, values));
        printf("\n---\n");
    }
  return cons(variables, values);
}

object *frame_variables(object *frame) {
    return car(frame);
}

object *frame_values(object *frame) {
    return cdr(frame);
}

void add_binding_to_frame(object *var, object *val,
                          object *frame) {
    set_car(frame, cons(var, car(frame)));
    set_cdr(frame, cons(val, cdr(frame)));
}

object *extend_environment(object *vars, object *vals,
                           object *base_env) {
    return cons(make_frame(vars, vals), base_env);
}

object *lookup_variable_value(object *var, object *env) {
    object *frame;
    object *vars;
    object *vals;
    if (debug)
    {
        fprintf(stderr, "entering lookup_variable_value searching for %s\n", var->data.symbol.value);
    }
    while (!is_the_empty_list(env)) {
        frame = first_frame(env);
        vars  = frame_variables(frame);
        vals  = frame_values(frame);
        if (debug)
        {
            fprintf(stderr, "1 searching symbol %s\n", var->data.symbol.value);
            fprintf(stderr, "1 vars %p\n", vars);
        }
        while (!is_the_empty_list(vars)) {
            if (is_pair(vars)) {
                if (var == car(vars)) {
                    if (debug)
                    {
                        fprintf(stderr, "vals---\n");
                        write(stdout, is_pair(vals) ? car(vals) : the_empty_list);
                        fflush(stdout);
                        fprintf(stderr, "\nend---\n");

                    }
                    return is_pair(vals) ? car(vals) : the_empty_list;
                }
            }
            else if(is_symbol(vars)) {
                if (debug)
                {
                    fprintf(stderr, "2 searched symbol %s\n", var->data.symbol.value);
                    fprintf(stderr, "last cdr symbol %s\n", vars->data.symbol.value);
                }
                if (var == vars) {
                    if (debug)
                    {
                        fprintf(stderr, "vals---\n");
                        write(stdout, vals);
                        fflush(stdout);
                        fprintf(stderr, "\nend---\n");
                    }
                    return vals;
                }
                else
                {
                  break;
                }
            }
            vars = cdr(vars);
            vals = cdr(vals);
        }
        env = enclosing_environment(env);
    }
    fprintf(stderr, "unbound variable, %s\n", var->data.symbol.value);
    exit(1);
}

void set_variable_value(object *var, object *val, object *env) {
    object *frame;
    object *vars;
    object *vals;
    object *prevals;

    while (!is_the_empty_list(env)) {
        frame = first_frame(env);
        vars  = frame_variables(frame);
        vals  = frame_values(frame);

        if (debug)
        {
            printf("\n---env\n");   write(stdout, env);
            printf("\n---frame\n"); write(stdout, frame);
            printf("\n---vars\n");  write(stdout, vars);
            printf("\n---vals\n");  write(stdout, vals);
            printf("\n---\n");
        }

        while (!is_the_empty_list(vars)) {
            /* if (var == car(vars)) { */
            /*     set_car(vals, val); */
            /*     return; */
            /* } */
            if (is_pair(vars)) {
                // printf("ispair\n");

                if (var == car(vars)) {
                    if (debug)
                    {
                        printf("found match\n");
                        printf("\n---vals\n");
                        write(stdout, vals);
                    }
                    if (is_pair(vals))
                    {
                        set_car(vals, val);
                        return;
                    }
                    else        /* TODO */
                    {
                        set_cdr(prevals, cons(val, the_empty_list));
                        return;
                    }
                }
            }
            else if(is_symbol(vars)) {
                if (debug)
                {
                    printf("symbol\n");
                    fprintf(stderr, "2 searched symbol %s\n", var->data.symbol.value);
                    fprintf(stderr, "last cdr symbol %s\n", vars->data.symbol.value);
                }
                if (var == vars) {
                    if (debug)
                    {
                        printf("\n---vals\n");  write(stdout, vals);
                        printf("\n---prevals\n");  write(stdout, prevals);
                    }
                    // assert(0);
                    set_cdr(prevals, val);
                    // return vals;
                    return;
                }
                else
                {
                    if (debug)
                    {
                        printf("\nx yes\n");
                    }
                    // assert(0);
                    break;
                }
            }

            vars = cdr(vars);
            prevals = vals;
            vals = cdr(vals);
        }
        env = enclosing_environment(env);
    }
    fprintf(stderr, "unbound variable, %s\n", var->data.symbol.value);
    exit(1);
}

void define_variable(object *var, object *val, object *env) {
    object *frame;
    object *vars;
    object *vals;
    object *prevals;

    frame = first_frame(env);
    vars = frame_variables(frame);
    vals = frame_values(frame);

    while (!is_the_empty_list(vars)) {
        /* if (var == car(vars)) { */
        /*     set_car(vals, val); */
        /*     return; */
        /* } */

        if (is_pair(vars)) {
            // printf("ispair\n");

            if (var == car(vars)) {
                if (debug)
                {
                    printf("found match\n");
                    printf("\n---vals\n");  write(stdout, vals);
                }
                if (is_pair(vals))
                {
                    set_car(vals, val);
                    return;
                }
                else
                {
                    assert(0);
                }
            }
        }
        else if(is_symbol(vars)) {
            if (debug)
            {
                printf("symbol\n");
                fprintf(stderr, "2 searched symbol %s\n", var->data.symbol.value);
                fprintf(stderr, "last cdr symbol %s\n", vars->data.symbol.value);
            }
            if (var == vars) {
                if (debug)
                {
                    printf("\n---vals\n");  write(stdout, vals);
                    printf("\n---prevals\n");  write(stdout, prevals);
                }
                // assert(0);
                set_cdr(prevals, val);
                // return vals;
                return;
            }
            else
            {
                printf("\nx yes\n");
                // assert(0);
                break;
            }
        }

        vars = cdr(vars);
        prevals = vals;
        vals = cdr(vals);
    }
    add_binding_to_frame(var, val, frame);
}

object *setup_environment(void) {
    object *initial_env;

    initial_env = extend_environment(
                      the_empty_list,
                      the_empty_list,
                      the_empty_environment);
    return initial_env;
}

object *make_environment(void) {
    object *env;

    env = setup_environment();
    populate_environment(env);
    return env;
}
