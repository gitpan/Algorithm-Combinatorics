# -*-: Mode:C -*-

package Algorithm::Combinatorics::C;

our $VERSION = '0.10';
use Inline C => <<"END_OF_C_CODE", VERSION => '0.10', NAME => 'Algorithm::Combinatorics::C';

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
#define GET(av, i)         (SvIVX(*av_fetch(av, i, 0)))


/**
  * This provisional implementation emulates what we do by hand.
  */
int __next_combination(SV* indices_avptr, int max_n)
{
    int i, j;
    IV  n;
    I32 offset, len_indices;
    SV* index;

    /* Workaround for some AVPtr problems reported. */
    AV* indices = (AV*) SvRV(indices_avptr);

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


/**
  * This provisional implementation emulates what we do by hand.
  */
int __next_combination_with_repetition(SV* indices_avptr, int max_n)
{
    int i, j;
    IV  n;
    I32 len_indices;

    /* Workaround for some AVPtr problems reported. */
    AV* indices = (AV*) SvRV(indices_avptr);

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


/**
  * This provisional implementation emulates what we do by hand, keeping
  * and array of boleans (used) to keep track of the indices in use.
  */
int __next_variation(SV* indices_avptr, SV* used_avptr, int max_n)
{
    int i, j;
    I32 len_indices;
    SV* index;
    IV  n;

    /* Workaround for some AVPtr problems reported. */
    AV* indices = (AV*) SvRV(indices_avptr);
    AV* used    = (AV*) SvRV(used_avptr);

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


/**
  * This provisional implementation emulates what we do by hand.
  */
int __next_variation_with_repetition(SV* indices_avptr, int max_n)
{
    int i;
    I32 len_indices;
    SV* index;

    /* Workaround for some AVPtr problems reported. */
    AV* indices = (AV*) SvRV(indices_avptr);

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


/**
  * Algorithm L (Lexicographic permutation generation), adapted from [1].
  * I used "h" instead of the letter "l" for the sake of readability.
  *
  * This algorithm goes back at least to the 18th century, and have been rediscovered
  * ever since.
  */
int __next_permutation(SV* indices_avptr, int max_n)
{
    int j, h, aj, k;

    /* Workaround for some AVPtr problems reported. */
    AV* indices = (AV*) SvRV(indices_avptr);

    /* [Find j.] Find the element a(j) behind the longest descreasing tail. */
    for (j = max_n-1; j >= 0 && GET(indices, j) > GET(indices, j+1); --j)
        ;
    if (j == -1)
        return -1;

    /* [Increase a(j).] Find the rightmost element a(h) greater than a(j). */
    aj = GET(indices, j);
    for (h = max_n; aj > GET(indices, h); --h)
        ;
    __swap(indices, j, h);

    /* [Reverse a(j+1)...a(max_n)] Reverse the tail. */
    for (k = j+1, h = max_n; k < h; ++k, --h)
        __swap(indices, k, h);

    /* Done. */
    return 1;
}

/* Swap elements i and j from av. */
void __swap(AV* av, int i, int j)
{
    IV tmp;

    tmp = SvIVX(*av_fetch(av, i, 0));
    UPDATE(av, i, GET(av, j));
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

