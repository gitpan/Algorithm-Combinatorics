package Algorithm::Combinatorics::C;

use Inline C => <<'END_OF_C_CODE';

/**
 * These subroutines implement the actual iterators.
 * 
 * The real combinatorics are done in-place on a private array of indices
 * that is guaranteed to hold IVs. Once the next tuple has been computed
 * on that array the corresponding slice of data is copied into out.
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

int __next_combination(AV* indices, int max_n)
{
    int i, j;
    IV  n;
    I32 offset, len_indices;
    SV* index;

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

int __next_combination_with_repetition(AV* indices, int max_n)
{
    int i, j;
    IV  n;
    I32 len_indices;

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


int __next_variation(HV* used, AV* indices, int max_n)
{
    int i, j;
    I32 len_indices;
    SV* index;
    IV  n;
    HE* he;

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
                  return i;
             }
        }
    }

    return -1;
}


int __next_variation_with_repetition(AV* indices, int max_n)
{
    int i;
    I32 len_indices;
    SV* index;

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
int __next_permutation(AV* indices, int max_n)
{
    int i, j, k;
    
    i = max_n;
    while (i > 0 && GET(indices, i-1) > GET(indices, i))
        --i;
    
    if (i == 0)
        return -1;

    j = i + 1;  
    while (j <= max_n && GET(indices, i-1) < GET(indices, j))
        ++j;
    
    __swap(indices, i-1, j-1);
    
    k = (max_n-i)/2;
    for (j = 0; j <= k; j++)
        __swap(indices, i+j, max_n-j);      
    
    return 1;
}

void __swap(AV* av, int i, int j)
{
	IV tmp;
	
	if (i != j) {		
        tmp = SvIVX(*av_fetch(av, i, 0));
        UPDATE(av, i, SvIVX(*av_fetch(av, j, 0)));
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

