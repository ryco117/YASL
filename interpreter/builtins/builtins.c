#include <inttypes.h>
#include <string.h>
#include <debug.h>

#include "builtins.h"

int yasl_print(VM* vm) {
    YASL_Object v = vm->stack[vm->sp--];    // pop value from top of the stack ...
    if (v.type == LIST) {
        ls_print(v.value.lval);
        printf("\n");
        return 0;
    } else if (v.type == MAP) {
        ht_print(v.value.mval);
        printf("\n");
        return 0;
    }
    int return_value = print(v);
    printf("\n");
    return return_value;
}

int yasl_input(VM* vm) {
    print(POP(vm));
    printf("\n");
    int ch;
    size_t len = 0;
    size_t size = 10;
    char *str = realloc(NULL, sizeof(char)*size);

    if (!str) return -1; // ERROR
    while(EOF!=(ch=fgetc(stdin)) && ch != '\n'){
        str[len++]=ch;
        if(len==size){
            str = realloc(str, sizeof(char)*(size+=16));
            if(!str)return -1; // ERROR
        }
    }
    str = realloc(str, sizeof(char)*len);
    vm->stack[++vm->sp].value.sval = new_sized_string8_from_mem(len, str);
    vm->stack[vm->sp].type = STR8;
    return 0;
}

/* int yasl_typeof(VM *vm) {
    return 0;
} */

/* TODO: implement for all types
 * "tofloat64":    0x0A,
 * "toint64":      0x0B,
 * "tobool":       0x0C,
 * "tostr8":       0x0D,
 * "tolist":       0x0E,
 * "tomap":        0x0F,
*/

int yasl_open(VM* vm) {     //TODO: fix bug relating to file pointer
    YASL_Object mode_str = POP(vm);
    YASL_Object str = POP(vm);
    if (mode_str.type != STR8) {
        printf("Error: open(...) expected type %s as second argument, got type %s\n", YASL_TYPE_NAMES[STR8], YASL_TYPE_NAMES[str.type]);
        return -1;
    }
    if (str.type != STR8) {
        printf("Error: open(...) expected type %s as first argument, got type %s\n", YASL_TYPE_NAMES[STR8], YASL_TYPE_NAMES[str.type]);
        return -1;
    }
    char *buffer = malloc((str.value.sval)->length + 1);
    memcpy(buffer, (str.value.sval)->str, (str.value.sval)->length);
    buffer[(str.value.sval)->length] = '\0';
    char *mode = malloc((mode_str.value.sval)->length + 1);
    memcpy(mode, (mode_str.value.sval)->str, (mode_str.value.sval)->length);
    mode[(mode_str.value.sval)->length] = '\0';

    FILE *f;  // r, w, a, r+, w+, a+
    if (!strcmp(mode, "r")) {
        f = fopen(buffer, "r");
    } else if (!strcmp(mode, "w")) {
        f = fopen(buffer, "w");
    } else if (!strcmp(mode, "a")) {
        f = fopen(buffer, "a");
    } else if (!strcmp(mode, "r+")) {
        f = fopen(buffer, "r+");
    } else if (!strcmp(mode, "w+")) {
        f = fopen(buffer, "w+");
    } else if (!strcmp(mode, "a+")) {
        f = fopen(buffer, "a+");
    } else if (!strcmp(mode, "rb")) {
        f = fopen(buffer, "rb");
    } else if (!strcmp(mode, "wb")) {
        f = fopen(buffer, "wb");
    } else if (!strcmp(mode, "ab")) {
        f = fopen(buffer, "ab");
    } else {
        printf("Error: invalid second argument: %s\n", mode);
        return -1;
    }
    vm->stack[++vm->sp].value.fval = f;
    vm->stack[vm->sp].type = FILEH;
    YASL_DEBUG_LOG("%s\n", "file opened successfully.");
    return 0;
}


int yasl_popen(VM* vm) {     //TODO: fix bug relating to file pointer
    YASL_Object mode_str = POP(vm);
    YASL_Object str = POP(vm);
    if (mode_str.type != STR8) {
        printf("Error: popen(...) expected type %x as second argument, got type %x\n", STR8, str.type);
        return -1;
    }
    if (str.type != STR8) {
        printf("Error: popen(...) expected type %x as first argument, got type %x\n", STR8, str.type);
        return -1;
    }
    char *buffer = malloc((str.value.sval)->length + 1);
    memcpy(buffer, (str.value.sval)->str, (str.value.sval)->length);
    buffer[(str.value.sval)->length] = '\0';
    char *mode = malloc((mode_str.value.sval)->length + 1);
    memcpy(mode, (mode_str.value.sval)->str, (mode_str.value.sval)->length);
    mode[(mode_str.value.sval)->length] = '\0';

    FILE *f;  // r, w, a, r+, w+, a+
    if (!strcmp(mode, "r")) {
        f = popen(buffer, "r");
    } else if (!strcmp(mode, "w")) {
        f = popen(buffer, "w");
    } else {
        printf("Error: invalid second argument: %s\n", mode);
        return -1;
    }
    vm->stack[++vm->sp].value.fval = f;
    vm->stack[vm->sp].type = FILEH;
    YASL_DEBUG_LOG("%s\n", "process opened successfully.");
    return 0;
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                   *
 *                                                                                                                   *
 *                                                 VTABLES                                                           *
 *                                                                                                                   *
 *                                                                                                                   *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

VTable_t* float64_builtins() {
    VTable_t* vt = new_vtable();
    vt_insert(vt, M_TOINT64, (int64_t)&float64_toint64);
    vt_insert(vt, M_TOSTR,   (int64_t)&float64_tostr);
    return vt;
}

VTable_t* int64_builtins() {
    VTable_t* vt = new_vtable();
    vt_insert(vt, M_TOFLOAT64, (int64_t)&int64_tofloat64);
    vt_insert(vt, M_TOSTR,     (int64_t)&int64_tostr);
    return vt;
}

VTable_t* bool_builtins() {
    VTable_t* vt = new_vtable();
    vt_insert(vt, M_TOSTR, (int64_t)&bool_tostr);
    return vt;
}

VTable_t* str8_builtins() {
    VTable_t* vt = new_vtable();
    vt_insert(vt, M_TOBOOL,     (int64_t)&str_tobool);
    vt_insert(vt, M_TOSTR,      (int64_t)&str_tostr);
    vt_insert(vt, M_UPCASE,     (int64_t)&str_upcase);
    vt_insert(vt, M_DOWNCASE,   (int64_t)&str_downcase);
    vt_insert(vt, M_ISALNUM,    (int64_t)&str_isalnum);
    vt_insert(vt, M_ISAL,       (int64_t)&str_isal);
    vt_insert(vt, M_ISNUM,      (int64_t)&str_isnum);
    vt_insert(vt, M_ISSPACE,    (int64_t)&str_isspace);
    vt_insert(vt, M_STARTSWITH, (int64_t)&str_startswith);
    vt_insert(vt, M_ENDSWITH,   (int64_t)&str_endswith);
    vt_insert(vt, M_SEARCH,     (int64_t)&str_search);
    vt_insert(vt, M_SPLIT,      (int64_t)&str_split);
    vt_insert(vt, M_LTRIM,      (int64_t)&str_ltrim);
    vt_insert(vt, M_RTRIM,      (int64_t)&str_rtrim);
    vt_insert(vt, M_TRIM,      (int64_t)&str_trim);
    vt_insert(vt, M___GET,      (int64_t)&str___get);
    return vt;
}

VTable_t* list_builtins() {
    VTable_t* vt = new_vtable();
    vt_insert(vt, M_APPEND, (int64_t)&list_append);
    vt_insert(vt, M___GET,  (int64_t)&list___get);
    vt_insert(vt, M___SET,  (int64_t)&list___set);
    vt_insert(vt, M_SEARCH,  (int64_t)&list_search);
    return vt;
}

VTable_t* map_builtins() {
    VTable_t* vt = new_vtable();
    vt_insert(vt, M_KEYS,   (int64_t)&map_keys);
    vt_insert(vt, M_VALUES, (int64_t)&map_values);
    vt_insert(vt, M___GET,  (int64_t)&map___get);
    vt_insert(vt, M___SET,  (int64_t)&map___set);
    return vt;
}

VTable_t* file_builtins() {
    VTable_t* vt = new_vtable();
    vt_insert(vt, M_CLOSE,    (int64_t)&file_close);
    vt_insert(vt, M_PCLOSE,   (int64_t)&file_pclose);
    vt_insert(vt, M_READ,     (int64_t)&file_read);
    vt_insert(vt, M_WRITE,    (int64_t)&file_write);
    vt_insert(vt, M_READLINE, (int64_t)&file_readline);
    return vt;
}
