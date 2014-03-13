if exists('g:loaded_clang_refactor')
  finish
endif

try
    call operator#user#define('clang-refactor', 'operator#clang_refactor#do', 'let g:operator#clang_refactor#save_pos = getpos(".") \| let g:operator#clang_refactor#save_screen_pos = line("w0")')
catch /^Vim\%((\a\+)\)\=:E117/
    " vim-operator-user is not installed
endtry

command! -range=% -nargs=0 ClangRefactor call clang_refactor#replace(<line1>, <line2>)

command! -range=% -nargs=0 ClangRefactorEchoRefactortedCode echo clang_refactor#refactor(<line1>, <line2>)

let g:loaded_clang_refactor = 1
