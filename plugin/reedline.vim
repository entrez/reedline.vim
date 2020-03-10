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
cno <C-a> <C-\>e<SID>reedline(-1, -1, 0, 0)<CR>
" C-e jumps to end of line
cno <C-e> <C-\>e<SID>reedline(1, -1, 0, 0)<CR>
" C-k deletes everything from cursor to end of line
cno <C-k> <C-\>e<SID>reedline(1, -1, 1, 0)<CR>
" C-p and C-n cycle up & down through cmd history
cno <C-p> <up>
cno <C-n> <down>
" C-b moves 1 char left, M-b moves 1 word left
cno <C-b> <left>
exec 'cno ' . <SID>shortcutmeta('b') . ' <C-\>e<SID>reedline(-1, 0, 0, 0)<CR>'
" C-f moves 1 char right, M-f moves 1 word right
cno <C-f> <right>
exec 'cno ' . <SID>shortcutmeta('f') . ' <C-\>e<SID>reedline(1, 0, 0, 0)<CR>'
" M-d and M-D delete from cursor to end of word
exec 'cno ' . <SID>shortcutmeta('<s-d>') . ' <C-\>e<SID>reedline(1, 0, 1, 0)<CR>'
exec 'cno ' . <SID>shortcutmeta('d') . ' <C-\>e<SID>reedline(1, 0, 1, 0)<CR>'
" M-<BS> deletes word until reaching punctuaction character
exec 'cno ' . <SID>shortcutmeta('<bs>') . ' <C-\>e<SID>reedline(-1, 0, 1, 0)<CR>'
" C-w deletes space-delimited word if g:space_delimited_C_w == 1 
" otherwise, acts like ALT-<BS>
cno <C-w> <C-\>e<SID>reedline(-1, 1, 1, 0)<CR>
" C-u deletes to start of line
cno <C-u> <C-\>e<SID>reedline(-1, -1, 1, 0)<CR>
" C-d deletes character to the right
cno <C-d> <C-\>e<SID>reedline(1, 1, 1, 0)<CR>
" M-= and M-? activate command completion
exec 'cno ' . <SID>shortcutmeta('=') . ' <C-i>'
exec 'cno ' . <SID>shortcutmeta('?') . ' <C-i>'
" M-l makes next word lowercase
exec 'cno ' . <SID>shortcutmeta('l') . ' <C-\>e<SID>reedline(1, 0, 0, -1)<CR>'
" M-u makes next word UPPERCASE
exec 'cno ' . <SID>shortcutmeta('u') . ' <C-\>e<SID>reedline(1, 0, 0, 1)<CR>'
" M-c makes next word Capitalized
exec 'cno ' . <SID>shortcutmeta('c') . ' <C-\>e<SID>reedline(1, 1, 0, 1)<CR>'
" C-y `yanks' (puts/pastes) last deleted word
cno <C-y> <C-\>e<SID>reedline(1, 0, 0, 2)<CR>
" C-t transposes characters
cno <C-t> <C-\>e<SID>reedline(1, 1, 0, 3)<CR>
" M-t transposes words
exec 'cno ' . <SID>shortcutmeta('t') . ' <C-\>e<SID>reedline(1, 0, 0, 3)<CR>'

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
            let tstamp = localtime()
            if exists('s:cmdline_yanked') && type(s:cmdline_yanked) == 3 
                        \ && tstamp - s:cmdline_yanked[0] < 1
                let s:cmdline_yanked = [tstamp,
                                      \ yanker . s:cmdline_yanked[1]]
            else 
                let s:cmdline_yanked = [tstamp, yanker]
            endif
        endif
    else
        let second_half_edited = a:special && !a:mode ? a:special<0?'':second_half[1:]
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
            let putter = exists('s:cmdline_yanked')?s:cmdline_yanked[1]:''
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
            let tstamp = localtime()
            if exists('s:cmdline_yanked') && type(s:cmdline_yanked) == 3 
                        \ && tstamp - s:cmdline_yanked[0] < 1
                let s:cmdline_yanked = [tstamp,
                                      \ s:cmdline_yanked[1] . yanker]
            else 
                let s:cmdline_yanked = [tstamp, yanker]
            endif
        endif
    endif
    return cmd_edited
endfunc
" }}}

" vim:fdm=marker:sw=4:ts=4:et
