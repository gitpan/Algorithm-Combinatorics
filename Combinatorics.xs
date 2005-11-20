/* -*- Mode: C -*- */

/**
 * These subroutines implement the actual iterators.
 *
 * The real combinatorics are done in-place on a private array of
 * indices that is guaranteed to hold IVs. Once the next tuple has been
 * computed the corresponding slice of data is copied in the Perl side.
 *
 * All the subroutines return -1 when there are no further tuples.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define UPDATE(av, i, n)   (SvIVX(AvARRAY(av)[i]) = n)
#define GETIV(av, i)       (SvIVX(AvARRAY(av)[i]))
#define GETAV(avptr)       ((AV*) SvRV(avptr))


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
 * This implementation emulates what we do by hand. It is faster than
 * Algorithm T from [2], which gives another lexicographic ordering.
 */
int __next_combination(SV* tuple_avptr, int max_n)
{
    AV* tuple = GETAV(tuple_avptr);
    int i, j;
    IV  n;
    I32 offset, len_tuple;
    SV* e;

    len_tuple = av_len(tuple);
    offset = max_n - len_tuple;
    for (i = len_tuple; i >= 0; --i) {
        e = *av_fetch(tuple, i, 0);
        n = SvIVX(e);
        if (n < i + offset) {
             SvIVX(e) = ++n;
             for (j = i+1; j <= len_tuple; ++j)
                  UPDATE(tuple, j, ++n);
             return i;
        }
    }

    return -1;
}


/**
 * This provisional implementation emulates what we do by hand.
 */
int __next_combination_with_repetition(SV* tuple_avptr, int max_n)
{
    AV* tuple = GETAV(tuple_avptr);
    int i, j;
    IV  n;
    I32 len_tuple;

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
    AV* tuple = GETAV(tuple_avptr);
    AV* used  = GETAV(used_avptr);
    int i, j;
    I32 len_tuple;
    SV* e;
    IV  n;

    len_tuple = av_len(tuple);
    for (i = len_tuple; i >= 0; --i) {
        e = *av_fetch(tuple, i, 0);
        n = SvIVX(e);
        UPDATE(used, n, 0);
        while (n++ < max_n) {
             if (!GETIV(used, n)) {
                  SvIVX(e) = n;
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
    AV* tuple = GETAV(tuple_avptr);
    int i;
    I32 len_tuple;
    SV* e;

    len_tuple = av_len(tuple);
    for (i = len_tuple; i >= 0; --i) {
        e = *av_fetch(tuple, i, 0);
        if (SvIVX(e) < max_n) {
            ++SvIVX(e);
            return i;
        }
        SvIVX(e) = 0;
    }

    return -1;
}

/**
 * Algorithm H (Loopless reflected mixed-radix Gray generation), from [1].
 *
 * [Initialize.] and [Visit.] are done in the Perl side.
 */
int __next_variation_with_repetition_gray_code(SV* tuple_avptr, SV* f_avptr, SV* o_avptr, int max_m)
{
    AV* tuple = GETAV(tuple_avptr);
    AV* f     = GETAV(f_avptr);
    AV* o     = GETAV(o_avptr);
    I32 n;
    IV j, aj;

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
    AV* tuple = GETAV(tuple_avptr);
    I32 max_n, j, h, k;
    IV aj;

    max_n = av_len(tuple);

    /* [Find j.] Find the element a(j) behind the longest decreasing tail. */
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
    AV* a = GETAV(a_avptr);
    AV* c = GETAV(c_avptr);
    int k;
    I32 n;
    IV ck;

    n = av_len(a) + 1;

    for (k = 1, ck = GETIV(c, k); ck == k; ++k, ck = GETIV(c, k))
        UPDATE(c, k, 0);

    if (k == n)
        return -1;

    ++ck;
    UPDATE(c, k, ck);

    k % 2 == 0 ? __swap(a, k, 0) : __swap(a, k, ck-1);

    return k;
}


/*
 * The only algorithms I have found by now are either recursive, or a
 * wrapper around permutations() that loops over all the elements to
 * jumps over permutations with fixed-points.
 *
 * We take here a mixed-approach, which consists on starting with the
 * algorithm in __next_permutation() and tweak a couple of places that
 * allow us to skip a significant number of permutations sometimes.
 *
 * Benchmarking shows this subroutine makes derangements() be more than
 * two an a half times faster than permutations().
 */
int __next_derangement(SV* tuple_avptr)
{
    AV* tuple = GETAV(tuple_avptr);
    I32 max_n, min_j, j, h, k;
    IV aj;

    max_n = av_len(tuple);
    min_j = max_n;

    while (1) {

         /* [Find j.] Find the element a(j) behind the longest decreasing tail. */
         for (j = max_n-1; j >= 0 && GETIV(tuple, j) > GETIV(tuple, j+1); --j)
              ;
         if (j == -1)
              return -1;

         if (min_j > j)
              min_j = j;

         /* [Increase a(j).] Find the rightmost element a(h) greater than a(j). */
         aj = GETIV(tuple, j);
         for (h = max_n; aj > GETIV(tuple, h); --h)
              ;
         __swap(tuple, j, h);

         if (GETIV(tuple, j) == j)
              continue;

         /* [Reverse a(j+1)...a(max_n)] Reverse the tail. */
         for (k = j+1, h = max_n; k < h; ++k, --h)
              __swap(tuple, k, h);

         for (k = max_n; k > min_j; --k)
              if (GETIV(tuple, k) == k)
                   break;
         if (k == min_j)
              break;
    }

    /* Done. */
    return 1;
}


/** -------------------------------------------------------------------
 *
 * XS stuff starts here.
 *
 */

MODULE = Algorithm::Combinatorics   PACKAGE = Algorithm::Combinatorics
PROTOTYPES: DISABLE

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
__next_derangement(tuple_avptr)
    SV* tuple_avptr
