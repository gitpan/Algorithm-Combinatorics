package Algorithm::Combinatorics::C;

use Inline C => <<'END_OF_C_CODE';

/**
 * These subroutines implement the actual iterators.
 * 
 * The real combinatorics are done in-place on a private array of indices
 * that is guaranteed to hold IVs. Once the next tuple has been computed
 * on that array the corresponding slice of data is copied into out.
 *
 * All the subroutines return -1 when there are no further tuples, or
 * the index of the element that was updated otherwise. I leave this a bit
 * ambiguous on purpose because by now we are only using == -1 and the
 * contract may change in future versions.
 *
 * As of this version variations() maintains a private hash table to be
 * able to keep track of the currently used indices, that is, the elements
 * of the indices array. This is used to be able to check efficiently whether
 * they are free to jump over them otherwise.
 *
 */


#define UPDATE(av, i, n) (sv_setiv(*av_fetch(av, i, 0), n))


int __next_combination(AV* indices, AV* data, AV* out)
{
    int i, j;
    IV  n;
    I32 offset, len_indices;
    SV* index;

    len_indices = av_len(indices);
    offset = av_len(data) - len_indices;
    for (i = len_indices; i >= 0; --i) {
        index = *av_fetch(indices, i, 0);
        n = SvIVX(index);
        if (n < i + offset) {
             sv_setiv(index, ++n);
             for (j = i+1; j <= len_indices; ++j)
                  UPDATE(indices, j, ++n);
             __slice_and_copy(i, indices, data, out);
             return i;
        }
    }

    return -1;
}


int __next_combination_with_repetition(AV* indices, AV* data, AV* out)
{
    int i, j;
    IV  n;
    I32 len_indices, max_n;

    len_indices = av_len(indices);
    max_n = av_len(data);
    for (i = len_indices; i >= 0; --i) {
        n = SvIVX(*av_fetch(indices, i, 0));
        if (n < max_n) {
             ++n;
             for (j = i; j <= len_indices; ++j)
                  UPDATE(indices, j, n);
             __slice_and_copy(i, indices, data, out);
             return i;
        }
    }

    return -1;
}


int __next_variation(HV* used, AV* indices, AV* data, AV* out)
{
    int i, j;
    I32 len_indices, max_n;
    SV* index;
    IV  n;
    HE* he;

    max_n = av_len(data);
    len_indices = av_len(indices);
    for (i = len_indices; i >= 0; --i) {
        index = *av_fetch(indices, i, 0);
        n = SvIVX(index);
        hv_delete_ent(used, index, 0, 0);
        while (n < max_n) {
             ++n;
             he = hv_fetch_ent(used, newSViv(n), 0, 0);
             if (he == NULL) {
                  sv_setiv(index, n);
                  hv_store_ent(used, newSViv(n), newSViv(i), 0);
                  for (j = i+1; j <= len_indices; ++j) {
                       n = -1;
                       while (n < max_n) {
                            ++n;
                            he = hv_fetch_ent(used, newSViv(n), 0, 0);
                            if (he == NULL) {
	                             UPDATE(indices, j, n);
                                 hv_store_ent(used, newSViv(n), newSViv(j), 0);
                                 break;
                            }
                       }
                  }
                  __slice_and_copy(i, indices, data, out);
                  return i;
             }
        }
    }

    return -1;
}


int __next_variation_with_repetition(AV* indices, AV* data, AV* out)
{
    int i;
    I32 len_indices, max_n;
    SV* index;

    max_n = av_len(data);
    len_indices = av_len(indices);
    for (i = len_indices; i >= 0; --i) {
        index = *av_fetch(indices, i, 0);
        if (SvIVX(index) < max_n) {
            sv_inc(index);
             __slice_and_copy(i, indices, data, out);
            return i;
        }
        sv_setiv(index, 0);
    }

    return -1;
}


void __slice_and_copy(int from, AV* indices, AV* data, AV* out)
{
     int i;
     I32 len_indices;
     IV  n;

     len_indices = av_len(indices);
     for (i = from; i <= len_indices; ++i) {
          n = SvIVX(*av_fetch(indices, i, 0));
          av_store(out, i, newSVsv(*av_fetch(data, n, 0)));
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
);

1;

