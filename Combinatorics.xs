/**
 * These subroutines implement the actual iterators.
 *
 * The real combinatorics are done in-place on a private array of indices
 * that is guaranteed to hold IVs. Once the next tuple has been computed
 * the corresponding slice of data is copied in the Perl side.
 *
 * All the subroutines return -1 when there are no further tuples.
 *
 * The array of indices in the function prototypes had type AV* in the 
 * first releases, but some errors were reported on FreeBSD and the
 * workaround was to change them to SV* and cast them to AV* afterwards.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define UPDATE(av, i, n)   (sv_setiv(*av_fetch(av, i, 0), n))
#define GETIV(av, i)       (SvIVX(*av_fetch(av, i, 0)))


/**
 * Swap the ith and jth elements in av. 
 *
 * Assumes av contains IVs.
 */
void __swap(AV* av, int i, int j) 
{
    IV tmp = GETIV(av, i);
    UPDATE(av, i, GETIV(av, j));
    UPDATE(av, j, tmp);
}

/**
 * This provisional implementation emulates what we do by hand.
 */
int __next_combination(SV* tuple_avptr, int max_n)
{
    int i, j;
    IV  n;
    I32 offset, len_tuple;
    SV* e;
    AV* tuple = (AV*) SvRV(tuple_avptr);

    len_tuple = av_len(tuple);
    offset = max_n - len_tuple;
    for (i = len_tuple; i >= 0; --i) {
        e = *av_fetch(tuple, i, 0);
        n = SvIVX(e);
        if (n < i + offset) {
             sv_setiv(e, ++n);
             for (j = i+1; j <= len_tuple; ++j)
                  UPDATE(tuple, j, ++n);
             return i;
        }
    }

    return -1;
}

/* TODO: buggy */
int __next_combination_new(SV* c_avptr, int j)
{
    IV x;
    I32 t;
    SV* e;
    AV* c = (AV*) SvRV(c_avptr);
    
    t = av_len(c) + 1;
    
    if (j > 0) {
        UPDATE(c, j, j);
        return j-1;
    }
    
    e = *av_fetch(c, 1, 0);
    if (SvIVX(e) + 1 < GETIV(c, 2)) {
        sv_inc(e);
        return j;
    }
    
    j = 2;
    while (1) {
        UPDATE(c, j-1, j-2);
        x = GETIV(c, j) + 1;
        if (x == GETIV(c, j+1))
            ++j;
        else
            break;
    }

    if (j > t)
        return -1;

    UPDATE(c, j, x);
    return j-1;
}


/**
 * This provisional implementation emulates what we do by hand.
 */
int __next_combination_with_repetition(SV* tuple_avptr, int max_n)
{
    int i, j;
    IV  n;
    I32 len_tuple;

    AV* tuple = (AV*) SvRV(tuple_avptr);

    len_tuple = av_len(tuple);
    for (i = len_tuple; i >= 0; --i) {
        n = GETIV(tuple, i);
        if (n < max_n) {
             ++n;
             for (j = i; j <= len_tuple; ++j)
                  UPDATE(tuple, j, n);
             return i;
        }
    }

    return -1;
}


/**
 * This provisional implementation emulates what we do by hand, keeping
 * and array of booleans (used) to keep track of the indices in use.
 */
int __next_variation(SV* tuple_avptr, SV* used_avptr, int max_n)
{
    int i, j;
    I32 len_tuple;
    SV* e;
    IV  n;

    /* Workaround for some AVPtr problems reported. */
    AV* tuple = (AV*) SvRV(tuple_avptr);
    AV* used    = (AV*) SvRV(used_avptr);

    len_tuple = av_len(tuple);
    for (i = len_tuple; i >= 0; --i) {
        e = *av_fetch(tuple, i, 0);
        n = SvIVX(e);
        UPDATE(used, n, 0);
        while (n++ < max_n) {
             if (!GETIV(used, n)) {
                  sv_setiv(e, n);
                  UPDATE(used, n, 1);
                  for (j = i+1; j <= len_tuple; ++j) {
                       n = -1;
                       while (n++ < max_n) {
                            if (GETIV(used, n) == 0) {
                                 UPDATE(tuple, j, n);
                                 UPDATE(used, n, 1);
                                 break;
                            }
                       }
                  }
                  return i;
             }
        }
    }

    return -1;
}

/**
 * This provisional implementation emulates what we do by hand.
 */
int __next_variation_with_repetition(SV* tuple_avptr, int max_n)
{
    int i;
    I32 len_tuple;
    SV* e;

    /* Workaround for some AVPtr problems reported. */
    AV* tuple = (AV*) SvRV(tuple_avptr);

    len_tuple = av_len(tuple);
    for (i = len_tuple; i >= 0; --i) {
        e = *av_fetch(tuple, i, 0);
        if (SvIVX(e) < max_n) {
            sv_inc(e);
            return i;
        }
        sv_setiv(e, 0);
    }

    return -1;
}

/**
 * Algorithm H (Loopless reflected mixed-radix Gray generation), from [1].
 *
 * [Initialize.] and [Visit.] are done in the Perl side.
 */
int __next_variation_with_repetition_gray_code(SV* tuple_avptr, SV* f_avptr, SV* o_avptr, int max_m) {
    I32 n;
    IV j, aj;

    /* Workaround for some AVPtr problems reported. */
    AV* tuple = (AV*) SvRV(tuple_avptr);
    AV* f     = (AV*) SvRV(f_avptr);
    AV* o     = (AV*) SvRV(o_avptr);
    
    n = av_len(tuple) + 1;
    
    /* [Choose j.] */
    j = GETIV(f, 0);
    UPDATE(f, 0, 0);
    
    /* [Change coordinate j.] */
    if (j == n)
        return -1;
    else
        UPDATE(tuple, j, GETIV(tuple, j) + GETIV(o, j));
    
    /* [Reflect?] */
    aj = GETIV(tuple, j);
    if (aj == 0 || aj == max_m) {
        UPDATE(o, j, -GETIV(o, j));
        UPDATE(f, j, GETIV(f, j+1));
        UPDATE(f, j+1, j+1);
    }
    
    return j;   
}


/**
 * Algorithm L (Lexicographic permutation generation), adapted from [1].
 * I used "h" instead of the letter "l" for the sake of readability.
 *
 * This algorithm goes back at least to the 18th century, and has been rediscovered
 * ever since.
 */
int __next_permutation(SV* tuple_avptr)
{
    int j, h, aj, k, max_n;

    /* Workaround for some AVPtr problems reported. */
    AV* tuple = (AV*) SvRV(tuple_avptr);
    max_n = av_len(tuple);

    /* [Find j.] Find the element a(j) behind the longest descreasing tail. */
    for (j = max_n-1; j >= 0 && GETIV(tuple, j) > GETIV(tuple, j+1); --j)
        ;
    if (j == -1)
        return -1;

    /* [Increase a(j).] Find the rightmost element a(h) greater than a(j). */
    aj = GETIV(tuple, j);
    for (h = max_n; aj > GETIV(tuple, h); --h)
        ;
    __swap(tuple, j, h);

    /* [Reverse a(j+1)...a(max_n)] Reverse the tail. */
    for (k = j+1, h = max_n; k < h; ++k, --h)
        __swap(tuple, k, h);

    /* Done. */
    return 1;
}

int __next_permutation_heap(SV* a_avptr, SV* c_avptr)
{
    int k;
    I32 n;
    IV ck;

    /* Workaround for some AVPtr problems reported. */    
    AV* a = (AV*) SvRV(a_avptr);
    AV* c = (AV*) SvRV(c_avptr);
    
    n = av_len(a) + 1;
    
    for (k = 1, ck = GETIV(c, k); ck == k; ck = GETIV(c, ++k))
        UPDATE(c, k, 0);
        
    if (k == n)
        return -1;

    ++ck;
    UPDATE(c, k, ck);

    k % 2 == 0 ? __swap(a, k, 0) : __swap(a, k, ck-1);
        
    return k;
}


/** -------------------------------------------------------------------
 *
 * XS stuff starts here.
 *
 */

MODULE = Algorithm::Combinatorics   PACKAGE = Algorithm::Combinatorics
PROTOTYPES: ENABLE

int
__next_combination(tuple_avptr, max_n)
    SV* tuple_avptr
    int max_n

int
__next_combination_with_repetition(tuple_avptr, max_n)
    SV* tuple_avptr
    int max_n

int
__next_variation(tuple_avptr, used_avptr, max_n)
    SV* tuple_avptr
    SV* used_avptr
    int max_n
    
int
__next_variation_with_repetition(tuple_avptr, max_n)
    SV* tuple_avptr
    int max_n

int
__next_variation_with_repetition_gray_code(tuple_avptr, f_avptr, o_avptr, max_m)
    SV* tuple_avptr
    SV* f_avptr
    SV* o_avptr
    int max_m

int
__next_permutation(tuple_avptr)
    SV* tuple_avptr
    
int
__next_permutation_heap(a_avptr, c_avptr)
    SV* a_avptr
    SV* c_avptr

int
__next_combination_new(c_avptr, j)
    SV* c_avptr
    int j