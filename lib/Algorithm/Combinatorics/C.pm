# -*- Mode: C -*-

package Algorithm::Combinatorics::C;

use Inline C => <<'END_OF_C_CODE';
/**
 * These subroutines implement the actual iterators.
 *
 * The real combinatorics are done in-place on a private array of indices
 * that is guaranteed to hold IVs. Once the next tuple has been computed
 * the corresponding slice of data is copied in the Perl side.
 *
 * All the subroutines return -1 when there are no further tuples.
 */

void __swap(AV* av, int i, int j);

#define UPDATE(av, i, n)   (sv_setiv(*av_fetch(av, i, 0), n))
#define GETIV(av, i)         (SvIVX(*av_fetch(av, i, 0)))


/**
 * This provisional implementation emulates what we do by hand.
 */
int __next_combination(SV* tuple_avptr, int max_n)
{
    int i, j;
    IV  n;
    I32 offset, len_tuple;
    SV* e;

    /* Workaround for some AVPtr problems reported. */
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


/**
 * This provisional implementation emulates what we do by hand.
 */
int __next_combination_with_repetition(SV* tuple_avptr, int max_n)
{
    int i, j;
    IV  n;
    I32 len_tuple;

    /* Workaround for some AVPtr problems reported. */
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
 * Algorithm L (Lexicographic permutation generation), adapted from [1].
 * I used "h" instead of the letter "l" for the sake of readability.
 *
 * This algorithm goes back at least to the 18th century, and has been rediscovered
 * ever since.
 */
int __next_permutation(SV* tuple_avptr, int max_n)
{
    int j, h, aj, k;

    /* Workaround for some AVPtr problems reported. */
    AV* tuple = (AV*) SvRV(tuple_avptr);

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
END_OF_C_CODE


use Exporter;
use base 'Exporter';

our @EXPORT = qw(
    __next_combination
    __next_combination_with_repetition
    __next_variation
    __next_variation_with_repetition
    __next_permutation
);

1;

