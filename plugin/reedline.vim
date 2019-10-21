if exists('*s:reedline')
    finish
endif

" s:shortcutmeta {{{
func! s:shortcutmeta(key)
    if has('nvim') || has('gui')
        let result = '<M-' . substitute(a:key, '\v(^\<|\>$)', '', 'g') . '>'
    else
        let result = '<Esc>' . a:key
    endif
    return result
endfunc
" }}}

" C-a jumps to start of line
cno <c-a> <c-\>e<sid>reedline(-1, -1, 0, 0)<cr>
" C-e jumps to end of line
cno <c-e> <c-\>e<sid>reedline(1, -1, 0, 0)<cr>
" C-k deletes everything from cursor to end of line
cno <c-k> <c-\>e<sid>reedline(1, -1, 1, 0)<cr>
" C-p and C-n cycle up & down through cmd history
cno <c-p> <up>
cno <c-n> <down>
" C-b moves 1 char left, M-b moves 1 word left
cno <c-b> <left>
exec 'cno ' . <sid>shortcutmeta('b') . ' <c-\>e<sid>reedline(-1, 0, 0, 0)<cr>'
" C-f moves 1 char right, M-f moves 1 word right
cno <c-f> <right>
exec 'cno ' . <sid>shortcutmeta('f') . ' <c-\>e<sid>reedline(1, 0, 0, 0)<cr>'
" M-d and M-D delete from cursor to end of word
exec 'cno ' . <sid>shortcutmeta('<s-d>') . ' <c-\>e<sid>reedline(1, 0, 1, 0)<cr>'
exec 'cno ' . <sid>shortcutmeta('d') . ' <c-\>e<sid>reedline(1, 0, 1, 0)<cr>'
" M-<BS> deletes word until reaching punctuaction character
exec 'cno ' . <sid>shortcutmeta('<bs>') . ' <c-\>e<sid>reedline(-1, 0, 1, 0)<cr>'
" C-w deletes space-delimited word if g:space_delimited_C_w == 1 
" otherwise, acts like ALT-<BS>
cno <c-w> <c-\>e<sid>reedline(-1, 1, 1, 0)<cr>
" C-u deletes to start of line
cno <c-u> <c-\>e<sid>reedline(-1, -1, 1, 0)<cr>
" C-d deletes character to the right
cno <c-d> <delete>
" M-= and M-? activate command completion
exec 'cno ' . <sid>shortcutmeta('=') . ' <c-i>'
exec 'cno ' . <sid>shortcutmeta('?') . ' <c-i>'
" M-l makes next word lowercase
exec 'cno ' . <sid>shortcutmeta('l') . ' <c-\>e<sid>reedline(1, 0, 0, -1)<cr>'
" M-u makes next word UPPERCASE
exec 'cno ' . <sid>shortcutmeta('u') . ' <c-\>e<sid>reedline(1, 0, 0, 1)<cr>'
" M-c makes next word Capitalized
exec 'cno ' . <sid>shortcutmeta('c') . ' <c-\>e<sid>reedline(1, 1, 0, 1)<cr>'
" C-y `yanks' (puts/pastes) last deleted word
cno <c-y> <c-\>e<sid>reedline(1, 0, 0, 2)<cr>
" C-t transposes characters
cno <c-t> <c-\>e<sid>reedline(1, 1, 0, 3)<cr>
" M-t transposes words
exec 'cno ' . <sid>shortcutmeta('t') . ' <c-\>e<sid>reedline(1, 0, 0, 3)<cr>'

" s:reedline {{{
func! s:reedline(direction, special, delete, mode)
    let pos = getcmdpos() - 1
    let cmd = getcmdline()
    if pos == 0
        let first_half = ''
        let second_half = cmd
    elseif pos == len(cmd)
        let first_half = cmd
        let second_half = ''
    else
        let first_half = cmd[:pos - 1]
        let second_half = cmd[pos:]
    endif
    if a:direction < 0
        let first_half_edited = a:special>0 && exists("g:space_delimited_C_w") && g:space_delimited_C_w 
                    \ ?substitute(first_half, '\v\S*\s*$', '', ''):a:special<0?''
                    \ :substitute(first_half, '\v[0-9A-Za-z]*[^0-9A-Za-z]*$', '', '')
        let lendiff = len(first_half) - len(first_half_edited)
        let yanker = first_half[-lendiff:]
        let cmd_edited = a:delete?first_half_edited . second_half:cmd
        call setcmdpos(pos + 1 - lendiff)
        if a:delete && len(yanker) > 0
            let s:cmdline_yanked = yanker
        endif
    else
        let second_half_edited = a:special&&!a:mode?''
                    \ :substitute(second_half, '\v^[^0-9A-Za-z]*[0-9A-Za-z]*', '', '')
        let lendiff = len(second_half) - len(second_half_edited) 
        let yanker = second_half[:lendiff-1]
        if abs(a:mode) == 1
            if a:special
                let splitword = matchlist(yanker, '\v^(\A*\a)(.*)')[1:2]
                let changedcase = toupper(splitword[0]) . tolower(splitword[1])
            else
                let changedcase = a:mode>0?toupper(yanker):tolower(yanker)
            endif
            let cmd_edited = first_half.changedcase.second_half_edited
        elseif a:mode == 2
            let putter = exists('s:cmdline_yanked')?s:cmdline_yanked:''
            let cmd_edited = first_half . putter . second_half
        elseif a:mode == 3
            if a:special
                let cmd_edited = first_half[:-2] . second_half[:0] . first_half[-1:] . second_half[1:]
                call setcmdpos(pos + 2)
            else
                let fm = matchlist(first_half . second_half[:0], '\v([0-9A-Za-z]{-})([^0-9A-Za-z]*)([0-9A-Za-z]+)$')
                let [smatch, edelim, ew2] = matchlist(second_half, '\v.?\zs([^0-9A-Za-z]*)([0-9A-Za-z]*)')[0:2]
                if len(fm)
                    let [fmatch, word1, delim, word2] = fm[0:3]
                    let [smatch, edelim, ew2] = matchlist(second_half, '\v.?\zs()([0-9A-Za-z]*)')[0:2]
                elseif len(ew2)
                    let [fmatch, word1, delim] = matchlist(first_half . second_half[:0],
                                \ '\v([0-9A-Za-z]*)([^0-9A-Za-z]*)$')[0:2]
                    let word2 = ew2
                    let ew2 = ''
                else
                    let [fmatch, word1, delim, word2] = matchlist(first_half . second_half[:0],
                                \ '\v([0-9A-Za-z]*)([^0-9A-Za-z]*)([0-9A-Za-z]*[^0-9A-Za-z]*)$')[0:3]
                    let [smatch, edelim, ew2] = matchlist(second_half, '\v.?\zs([^0-9A-Za-z]*)()')[0:2]
                endif
                if len(word1)
                    let startlen = len(second_half)>0?len(fmatch):len(fmatch)+1
                    let cmd_edited = first_half[:-startlen]
                                \ . word2 . ew2 . delim . edelim . word1
                                \ . second_half[len(smatch) + 1:]
                    call setcmdpos(len(first_half) + len(smatch) + 2)
                else
                    let cmd_edited = cmd
                endif
            endif
        else
            let cmd_edited = a:delete?first_half.second_half_edited:cmd
        endif
        if ! a:delete
            if a:mode == 2
                call setcmdpos(pos + 1 + len(cmd_edited) - len(cmd))
            elseif a:mode != 3
                call setcmdpos(pos + 1 + lendiff)
            endif
        elseif len(yanker) > 0
            let s:cmdline_yanked = yanker
        endif
    endif
    return cmd_edited
endfunc
" }}}
