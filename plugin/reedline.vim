" CTRL-a jumps to start of line
cno <c-a> <c-\>e<sid>reedline(-1, -1, 0, 0)<cr>
" CTRL-e jumps to end of line
cno <c-e> <c-\>e<sid>reedline(1, -1, 0, 0)<cr>
" CTRL-k deletes everything from cursor to end of line
cno <c-k> <c-\>e<sid>reedline(1, -1, 1, 0)<cr>
" CTRL-p and CTRL-n cycle up & down through cmd history
cno <c-p> <up>
cno <c-n> <down>
" CTRL-b moves 1 char left, ALT-b moves 1 word left
cno <c-b> <left>
cno <m-b> <c-\>e<sid>reedline(-1, 0, 0, 0)<cr>
" CTRL-f moves 1 char right, ALT-f moves 1 word right
cno <c-f> <right>
cno <m-f> <c-\>e<sid>reedline(1, 0, 0, 0)<cr>
" ALT-d and ALT-D delete from cursor to end of word
cno <m-s-d> <c-\>e<sid>reedline(1, 0, 1, 0)<cr>
cno <m-d> <c-\>e<sid>reedline(1, 0, 1, 0)<cr>
" ALT-<BS> deletes word until reaching punctuaction character
cno <m-bs> <c-\>e<sid>reedline(-1, 0, 1, 0)<cr>
" CTRL-w deletes space-delimited word
cno <c-w> <c-\>e<sid>reedline(-1, 1, 1, 0)<cr>
" CTRL-u deletes to start of line
cno <c-u> <c-\>e<sid>reedline(-1, -1, 1, 0)<cr>
" CTRL-d deletes character to the right
cno <c-d> <delete>
" ALT-= and ALT-? activate command completion
cno <m-=> <c-i>
cno <m-?> <c-i>
" ALT-l makes next word lowercase
cno <m-l> <c-\>e<sid>reedline(1, 0, 0, -1)<cr>
" ALT-u makes next word UPPERCASE
cno <m-u> <c-\>e<sid>reedline(1, 0, 0, 1)<cr>
" ALT-c makes next word Capitalized
cno <m-c> <c-\>e<sid>reedline(1, 1, 0, 1)<cr>
" CTRL-y `yanks' (puts/pastes) last deleted word
cno <c-y> <c-\>e<sid>reedline(1, 0, 0, 2)<cr>
" CTRL-t transposes characters
cno <c-t> <c-\>e<sid>reedline(1, 1, 0, 3)<cr>
" ALT-t transposes words
cno <m-t> <c-\>e<sid>reedline(1, 0, 0, 3)<cr>

if exists('*s:reedline')
    finish
endif

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
        let first_half_edited = !a:special?substitute(first_half, '\v[0-9A-Za-z]*[^0-9A-Za-z]*$', '', '')
                    \ :a:special<0?'':substitute(first_half, '\v\S*\s*$', '', '')
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
