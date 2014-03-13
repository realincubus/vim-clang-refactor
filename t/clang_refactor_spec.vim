" test with vim-vspec
" https://github.com/kana/vim-vspec

" helpers "{{{
" clang-refactor detection
function! s:detect_clang_refactor()
    for candidate in ['clang-refactor-3.4', 'clang-refactor', 'clang-refactor-HEAD']
        if executable(candidate)
            return candidate
        endif
    endfor
    throw 'not ok because detect clang-refactor could not be found in $PATH'
endfunction
let g:clang_refactor#command = s:detect_clang_refactor()

function! Chomp(s)
    return a:s =~# '\n$'
                \ ? a:s[0:len(a:s)-2]
                \ : a:s
endfunction

function! ChompHead(s)
    return a:s =~# '^\n'
                \ ? a:s[1:len(a:s)-1]
                \ : a:s
endfunction

function! GetBuffer()
    return join(getline(1, '$'), "\n")
endfunction

function! ClangRefactor(line1, line2)
    let opt = printf(" -lines=%d:%d -style='{BasedOnStyle: Google, IndentWidth: %d, UseTab: %s}' ", a:line1, a:line2, &l:shiftwidth, &l:expandtab==1 ? "false" : "true")
    let cmd = g:clang_refactor#command.opt.'./'.s:root_dir.'t/test.cpp --'
    return Chomp(system(cmd))
endfunction
"}}}

" setup {{{
let s:root_dir = ChompHead(Chomp(system('git rev-parse --show-cdup')))
execute 'set' 'rtp +=./'.s:root_dir

set rtp +=~/.vim/bundle/vim-operator-user
runtime! plugin/clang_refactor.vim

call vspec#customize_matcher('to_be_empty', function('empty'))
"}}}

" test for default settings {{{
describe 'default settings'
    it 'provide a default <Plug> mapping'
        Expect maparg('<Plug>(operator-clang-refactor)') not to_be_empty
    end

    it 'provide autoload functions'
        " load autload script
        silent! call clang_refactor#get_version()
        silent! call operator#clang_refactor#do()
        Expect exists('*operator#clang_refactor#do') to_be_true
        Expect exists('*clang_refactor#refactor') to_be_true
        Expect exists('*clang_refactor#get_version') to_be_true
    end

    it 'provide variables to customize this plugin'
        Expect exists('g:clang_refactor#extra_args') to_be_true
        Expect exists('g:clang_refactor#code_style') to_be_true
        Expect exists('g:clang_refactor#style_options') to_be_true
        Expect exists('g:clang_refactor#command') to_be_true
        Expect g:clang_refactor#extra_args to_be_empty
        Expect g:clang_refactor#code_style ==# 'google'
        Expect g:clang_refactor#style_options to_be_empty
        Expect executable(g:clang_refactor#command) to_be_true
    end

    it 'provide commands'
        Expect exists(':ClangRefactor') to_be_true
        Expect exists(':ClangRefactorEchoRefactortedCode') to_be_true
    end
end
"}}}

" test for clang_refactor#refactor() {{{
function! s:expect_the_same_output(line1, line2)
    Expect clang_refactor#refactor(a:line1, a:line2) ==# ClangRefactor(a:line1, a:line2)
endfunction

describe 'clang_refactor#refactor()'

    before
        new
        execute 'silent' 'edit!' './'.s:root_dir.'t/test.cpp'
    end

    after
        bdelete!
    end

    it 'refactors whole t/test.cpp'
        call s:expect_the_same_output(1, line('$'))
    end

    it 'refactors too long macro definitions'
        call s:expect_the_same_output(3, 3)
    end

    it 'refactors one line functions'
        call s:expect_the_same_output(5, 5)
    end

    it 'refactors initilizer list definition'
        call s:expect_the_same_output(9, 9)
    end

    it 'refactors for statement'
        call s:expect_the_same_output(11, 13)
    end

    it 'refactors too long string to multiple lines'
        call s:expect_the_same_output(17, 17)
    end

    it 'doesn''t move cursor'
        execute 'normal!' (1+line('$')).'gg'
        let pos = getpos('.')
        call s:expect_the_same_output(1, line('$'))
        Expect pos == getpos('.')
    end
end
" }}}

" test for <Plug>(operator-clang-refactor) {{{
describe '<Plug>(operator-clang-refactor)'

    before
        new
        execute 'silent' 'edit!' './'.s:root_dir.'t/test.cpp'
        map x <Plug>(operator-clang-refactor)
    end

    after
        bdelete!
    end

    it 'refactors in visual mode'
        let by_clang_refactor_command = ClangRefactor(1, line('$'))
        normal ggVGx
        let buffer = GetBuffer()
        Expect by_clang_refactor_command ==# buffer
    end

    it 'refactors a text object'
        " refactor for statement
        let by_clang_refactor_command = ClangRefactor(11, 13)
        " move to for statement block
        execute 12
        " do refactor a text object {}
        normal xa{
        let buffer = GetBuffer()
        Expect by_clang_refactor_command ==# buffer
    end

    it 'doesn''t move cursor'
        execute 12
        let pos = getpos('.')
        normal xa{
        Expect pos == getpos('.')
    end
end
" }}}

" test for :ClangRefactor {{{
describe ':ClangRefactor'

    before
        new
        execute 'silent' 'edit!' './'.s:root_dir.'t/test.cpp'
    end

    after
        bdelete!
    end

    it 'refactors the whole code in normal mode'
        let by_clang_refactor_command = ClangRefactor(1, line('$'))
        ClangRefactor
        let buffer = GetBuffer()
        Expect by_clang_refactor_command ==# buffer
    end

    it 'refactors selected code in visual mode'
        " refactor for statement
        let by_clang_refactor_command = ClangRefactor(11, 13)
        " move to for statement block
        execute 11
        normal! VjjV
        '<,'>ClangRefactor
        let buffer = GetBuffer()
        Expect by_clang_refactor_command ==# buffer
    end

    it 'doesn''t move cursor'
        execute 'normal!' (1+line('$')).'gg'
        let pos = getpos('.')
        ClangRefactor
        Expect pos == getpos('.')
    end

end
" }}}
