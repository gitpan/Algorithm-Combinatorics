# -*-: Mode:C -*-

package Algorithm::Combinatorics::C;

use Inline C => <<"END_OF_C_CODE";

/**
 * These subroutines implement the actual iterators.
 *
 * The real combinatorics are done in-place on a private array of indices
 * that is guaranteed to hold IVs. Once the next tuple has been computed
 * the corresponding slice of data is copied in the Perl side.
 *
 * All the subroutines return -1 when there are no further tuples.
 *
 * As of this version variations() maintains a private hash table to be
 * able to keep track of the currently used indices, that is, the elements
 * of the indices array. This is used to be able to check efficiently whether
 * they are free to jump over them otherwise.
 *
 */

void __swap(AV* av, int i, int j);

#define UPDATE(av, i, n)   (sv_setiv(*av_fetch(av, i, 0), n))
#define GET(av, i)         (SvIVX(*av_fetch(av, i, 0)))


int __next_combination(SV* indices, int max_n)
{
    int i, j;
    IV  n;
    I32 offset, len_indices;
    SV* index;

    /* Workaround for some AVPtr problems reported. */
    indices = (AV*) SvRV(indices);

    len_indices = av_len(indices);
    offset = max_n - len_indices;
    for (i = len_indices; i >= 0; --i) {
        index = *av_fetch(indices, i, 0);
        n = SvIVX(index);
        if (n < i + offset) {
             sv_setiv(index, ++n);
             for (j = i+1; j <= len_indices; ++j)
                  UPDATE(indices, j, ++n);
             return i;
        }
    }

    return -1;
}


int __next_combination_with_repetition(SV* indices, int max_n)
{
    int i, j;
    IV  n;
    I32 len_indices;

    /* Workaround for some AVPtr problems reported. */
    indices = (AV*) SvRV(indices);

    len_indices = av_len(indices);
    for (i = len_indices; i >= 0; --i) {
        n = GET(indices, i);
        if (n < max_n) {
             ++n;
             for (j = i; j <= len_indices; ++j)
                  UPDATE(indices, j, n);
             return i;
        }
    }

    return -1;
}


int __next_variation(SV* indices, SV* used, int max_n)
{
    int i, j;
    I32 len_indices;
    SV* index;
    IV  n;

    /* Workaround for some AVPtr problems reported. */
    indices = (AV*) SvRV(indices);
    used    = (AV*) SvRV(used);

    len_indices = av_len(indices);
    for (i = len_indices; i >= 0; --i) {
        index = *av_fetch(indices, i, 0);
        n = SvIVX(index);
        UPDATE(used, n, 0);
        while (n++ < max_n) {
             if (!GET(used, n)) {
                  sv_setiv(index, n);
                  UPDATE(used, n, 1);
                  for (j = i+1; j <= len_indices; ++j) {
                       n = -1;
                       while (n++ < max_n) {
                            if (GET(used, n) == 0) {
                                 UPDATE(indices, j, n);
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


int __next_variation_with_repetition(SV* indices, int max_n)
{
    int i;
    I32 len_indices;
    SV* index;

    /* Workaround for some AVPtr problems reported. */
    indices = (AV*) SvRV(indices);

    len_indices = av_len(indices);
    for (i = len_indices; i >= 0; --i) {
        index = *av_fetch(indices, i, 0);
        if (SvIVX(index) < max_n) {
            sv_inc(index);
            return i;
        }
        sv_setiv(index, 0);
    }

    return -1;
}


/* Adapted from http://www.scielo.br/scielo.php?pid=S0104-65002001000200009&script=sci_arttext&tlng=en */
int __next_permutation(SV* indices, int max_n)
{
    int i, j, k;

    /* Workaround for some AVPtr problems reported. */
    indices = (AV*) SvRV(indices);

    /* Find the element (i) to the left of the longest descreasing tail,
       that is, the "1" in "2 3 1 6 5 4". */
    for (i = max_n; i > 0 && GET(indices, i-1) > GET(indices, i); --i)
        ;

    /* If that's the leftmost we are done. */
    if (i == 0)
        return -1;

    /* Find the first element (j) to the right which is greater than i-1. */
    k = GET(indices, i-1);
    for (j = i+1; j <= max_n && k < GET(indices, j); ++j)
        ;

    /* Swap them. */
    __swap(indices, i-1, j-1);

    /* Reverse the tail i..max_n. */
    k = (max_n-i)/2;
    for (j = 0; j <= k; j++)
        __swap(indices, i+j, max_n-j);

    /* Done. */
    return 1;
}

void __swap(AV* av, int i, int j)
{
    IV tmp;

    if (i != j) {
        tmp = SvIVX(*av_fetch(av, i, 0));
        UPDATE(av, i, GET(av, j));
        UPDATE(av, j, tmp);
    }
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

