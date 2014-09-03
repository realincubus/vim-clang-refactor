if exists('g:loaded_clang_refactor')
  finish
endif

try
    call operator#user#define('clang-refactor', 'operator#clang_refactor#do', 'let g:operator#clang_refactor#save_pos = getpos(".") \| let g:operator#clang_refactor#save_screen_pos = line("w0")')
catch /^Vim\%((\a\+)\)\=:E117/
    " vim-operator-user is not installed
endtry

command! -range=% -nargs=0 ClangRefactorPull call clang_refactor#replace(<line1>, <line2>, "-pull-temporaries")
command! -range=% -nargs=0 ClangRefactorRAII call clang_refactor#replace(<line1>, <line2>, "-use-raii")
command! -range=% -nargs=0 ClangRefactorPow call clang_refactor#replace(<line1>, <line2>, "-use-pow")
command! -range=% -nargs=0 ClangRefactorHypot call clang_refactor#replace(<line1>, <line2>,"-use-hypot")
command! -range=% -nargs=0 ClangRefactorUnary call clang_refactor#replace(<line1>, <line2>,"-use-unary-operators")
command! -range=% -nargs=0 ClangRefactorCompound call clang_refactor#replace(<line1>, <line2>, "-use-compound")
command! -range=% -nargs=0 ClangRefactorCompoundV call clang_refactor#replaceV(<line1>, col("'<"), <line2>, col("'>"), "-use-compound")
command! -range=% -nargs=0 ClangRefactorExtractV call clang_refactor#replaceV(<line1>, col("'<"), <line2>, col("'>"), "-extract-method")
command! -range=% -nargs=0 ClangRefactorRepairBrocken call clang_refactor#replace(<line1>, <line2>,"-use-repair-brocken-nullcheck")
command! -range=% -nargs=0 ClangRefactorCollapseIf call clang_refactor#replace(<line1>, <line2>,"-collapse-ifstmt")
"command! -range=% -nargs=1 ClangRefactorRenameVariable call clang_refactor#replace(<line1>, <line2>,"-rename-variable -new-name" . <f-args>)
command! -range=% -nargs=1 ClangRefactorRename call clang_refactor#replaceGlobalV(<line1>, col("'<"), <line2>, col("'>"), "-rename -new_name " . <f-args>)
command! -range=% -nargs=0 ClangRefactor call clang_refactor#replace(<line1>, <line2>,"")

"command! -range=% -nargs=0 ClangRefactorEchoRefactortedCode echo clang_refactor#refactor(<line1>, <line2>)

let g:loaded_clang_refactor = 1
