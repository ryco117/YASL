#include <interpreter/YASL_Object/YASL_Object.h>
#include "list_methods.h"

int list___get(VM *vm) {
    List_t *ls = POP(vm).value.lval;
    YASL_Object index = POP(vm);
    if (index.type != INT64) {
        return -1;
        PUSH(vm, UNDEF_C);
    } else if (index.value.ival < -ls->count || index.value.ival >= ls->count) {
        printf("IndexError\n");
        return -1;
        PUSH(vm, UNDEF_C);
    } else {
        if (index.value.ival >= 0) PUSH(vm, ls->items[index.value.ival]);
        else PUSH(vm, ls->items[index.value.ival + ls->count]);
    }
    return 0;
}

int list___set(VM* vm) {
    List_t *ls = POP(vm).value.lval;
    YASL_Object value = POP(vm);
    YASL_Object index = POP(vm);
    if (index.type != INT64) {
        return -1;
        PUSH(vm, UNDEF_C);
    } else if (index.value.ival < -ls->count || index.value.ival >= ls->count) {
        printf("IndexError\n");
        return -1;
        PUSH(vm, UNDEF_C);
    } else {
        if (index.value.ival >= 0) ls->items[index.value.ival] = value;
        else ls->items[index.value.ival + ls->count] = value;
        PUSH(vm, value);
    }
    return 0;
}


int list_append(VM* vm) {
    YASL_Object ls  = POP(vm);
    YASL_Object val = POP(vm);
    ls_append(ls.value.lval, val);
    PUSH(vm, UNDEF_C);
    return 0;
}

int list_search(VM* vm) {
    YASL_Object haystack = POP(vm);
    YASL_Object needle = POP(vm);
    YASL_Object index = UNDEF_C;
    int i;
    for (i = 0; i < haystack.value.lval->count; i++) {
        if (!FALSEY(isequal(haystack.value.lval->items[i], needle)))
            index = (YASL_Object) { .type = INT64, .value.ival = i };
    }
    PUSH(vm, index);
    return 0;
}