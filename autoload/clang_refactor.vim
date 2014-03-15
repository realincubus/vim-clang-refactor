let s:save_cpo = &cpo
set cpo&vim

" helper functions {{{
function! s:has_vimproc()
    if !exists('s:exists_vimproc')
        try
            silent call vimproc#version()
            let s:exists_vimproc = 1
        catch
            let s:exists_vimproc = 0
        endtry
    endif
    return s:exists_vimproc
endfunction

function! s:system(str, ...)
    let command = a:str
    let input = a:0 >= 1 ? a:1 : ''

    if a:0 == 0
        let output = s:has_vimproc() ?
                    \ vimproc#system(command) : system(command)
    elseif a:0 == 1
        let output = s:has_vimproc() ?
                    \ vimproc#system(command, input) : system(command, input)
    else
        " ignores 3rd argument unless you have vimproc.
        let output = s:has_vimproc() ?
                    \ vimproc#system(command, input, a:2) : system(command, input)
    endif

    return output
endfunction

function! s:make_style_options()
    let extra_options = ""
    for [key, value] in items(g:clang_refactor#style_options)
        let extra_options .= printf(", %s: %s", key, value)
    endfor
    return printf("'{BasedOnStyle: %s, IndentWidth: %d, UseTab: %s%s}'",
                        \ g:clang_refactor#code_style,
                        \ (exists('*shiftwidth') ? shiftwidth() : &l:shiftwidth),
                        \ &l:expandtab==1 ? "false" : "true",
                        \ extra_options)
endfunction

function! s:success(result)
    return (s:has_vimproc() ? vimproc#get_last_status() : v:shell_error) == 0
                \ && a:result !~# '^YAML:\d\+:\d\+: error: unknown key '
                \ && a:result !~# '^\n\?$'
endfunction

function! s:error_message(result)
    echoerr "clang-refactor has failed to refactor."
    "if a:result =~# '^YAML:\d\+:\d\+: error: unknown key '
    "    echohl ErrorMsg
    "    for l in split(a:result, "\n")[0:1]
    "        echomsg l
    "    endfor
    "    echohl None
    "endif
endfunction

"function! clang_refactor#get_version()
"    if &shell =~# 'csh$' && executable('/bin/bash')
"        let shell_save = &shell
"        set shell=/bin/bash
"    endif
"    try
"        return matchlist(split(s:system(g:clang_refactor#command.' --version 2>&1'), "\n")[1], '\(\d\+\)\.\(\d\+\)')[1:2]
"    finally
"        if exists('l:shell_save')
"            let &shell = shell_save
"        endif
"    endtry
"endfunction
" }}}

" variable definitions {{{
function! s:getg(name, default)
    " backward compatibility
    if exists('g:operator_'.substitute(a:name, '#', '_', ''))
        echoerr 'g:operator_'.substitute(a:name, '#', '_', '').' is deprecated. Please use g:'.a:name
        return g:operator_{substitute(a:name, '#', '_', '')}
    else
        return get(g:, a:name, a:default)
    endif
endfunction

let g:clang_refactor#command = s:getg('clang_refactor#command', 'clang-refactor')
if ! executable(g:clang_refactor#command)
    echoerr "clang-refactor is not found. check g:clang_refactor#command."
    let &cpo = s:save_cpo
    unlet s:save_cpo
    finish
endif

let g:clang_refactor#extra_args = s:getg('clang_refactor#extra_args', "")
if type(g:clang_refactor#extra_args) == type([])
    let g:clang_refactor#extra_args = join(g:clang_refactor#extra_args, " ")
endif

let g:clang_refactor#code_style = s:getg('clang_refactor#code_style', 'google')
let g:clang_refactor#style_options = s:getg('clang_refactor#style_options', {})
" }}}

" check version of clang-refactor "{{{
"let s:version = clang_refactor#get_version()
"if s:version[0] < 3 || (s:version[0] == 3 && s:version[1] < 4)
"    echoerr 'clang-refactor 3.3 or earlier is not supported for the lack of aruguments'
"endif
"}}}

function! clang_refactor#refactorV(line1, col1, line2, col2, transformtype)
    let args = printf(" %s %s -lines=%s-%s:%s-%s", expand('%:p'), a:transformtype, a:line1, a:col1, a:line2, a:col2)
    let clang_refactor = printf("%s %s ", g:clang_refactor#command, args)
    echo clang_refactor
    return s:system(clang_refactor)
endfunction
" refactor codes {{{
function! clang_refactor#refactor(line1, line2, transformtype)
"    let args = printf(" -lines=%d:%d -style=%s %s",
"                \     a:line1,
"                \     a:line2,
"                \     s:make_style_options(),
"                \     g:clang_refactor#extra_args)
    let args = printf(" %s %s", expand('%:p'), a:transformtype )

    "let clang_refactor = printf("%s %s --", g:clang_refactor#command, args)
    let clang_refactor = printf("%s %s ", g:clang_refactor#command, args)
    echo clang_refactor
    "return s:system(clang_refactor, join(getline(1, '$'), "\n"))
    return s:system(clang_refactor)
endfunction
" }}}

function! clang_refactor#replaceV(line1, col1, line2, col2, transformtype )
    let pos_save = getpos('.')
    let sel_save = &l:selection
    let &l:selection = "inclusive"
    let [save_g_reg, save_g_regtype] = [getreg('g'), getregtype('g')]

    try
        let refactorted = clang_refactor#refactorV(a:line1, a:col1, a:line2, a:col2, a:transformtype)

	e
    finally
        call setreg('g', save_g_reg, save_g_regtype)
        let &l:selection = sel_save
        call setpos('.', pos_save)
    endtry

endfunction

" replace buffer {{{
function! clang_refactor#replace(line1, line2, transformtype )
    let pos_save = getpos('.')
    let sel_save = &l:selection
    let &l:selection = "inclusive"
    let [save_g_reg, save_g_regtype] = [getreg('g'), getregtype('g')]

    try
        let refactorted = clang_refactor#refactor(a:line1, a:line2, a:transformtype)

	e
        "if s:success(refactorted)
        "    call setreg('g', refactorted, 'v')
        "    silent keepjumps normal! ggVG"gp
        "else
        "    call s:error_message(refactorted)
        "endif
    finally
        call setreg('g', save_g_reg, save_g_regtype)
        let &l:selection = sel_save
        call setpos('.', pos_save)
    endtry
endfunction
" }}}

let &cpo = s:save_cpo
unlet s:save_cpo
