;;; init.el --- user-init-file                    -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;;; Early birds

;; Produce backtraces when errors occur: can be helpful to diagnose startup issues
;; (setq debug-on-error t)

(progn ; `startup'
  (defvar before-user-init-time (current-time)
    "Value of `current-time' when Emacs begins loading `user-init-file'.")
  (message "Loading Emacs...done (%.3fs)"
           (float-time (time-subtract before-user-init-time
                                      before-init-time)))
  (setq user-init-file (or load-file-name buffer-file-name))
  (setq user-emacs-directory (file-name-directory user-init-file))
  (message "Loading %s..." user-init-file)
  (setq inhibit-startup-buffer-menu t)
  (setq inhibit-startup-screen t)
  (setq ring-bell-function #'ignore)
  (setq-default fill-column 80)
  ;; Adjust garbage collection threshold for early startup (see use of gcmh below)
  (setq gc-cons-threshold (* 128 1024 1024))
  ;; General performance tuning
  (setq jit-lock-defer-time 0)
  ;; Process performance tuning
  (setq read-process-output-max (* 4 1024 1024))
  (setq process-adaptive-read-buffering nil))

(eval-and-compile ; `use-package'
  (setq use-package-enable-imenu-support t)
  (setq use-package-expand-minimally t)
  (setq use-package-compute-statistics t)
  (require  'use-package))

(use-package no-littering
  :vc (:url "https://github.com/emacscollective/no-littering" :rev :latest))

(use-package custom
  :no-require t
  :config
  (setq custom-file (no-littering-expand-etc-file-name "custom.el"))
  (when (file-exists-p custom-file)
    (load custom-file)))

(use-package server
  :hook (after-init . (lambda ()
                        (unless (server-running-p)
                          (server-start)))))

(progn ; `startup'
  (message "Loading early birds...done (%.3fs)"
           (float-time (time-subtract (current-time)
                                      before-user-init-time))))

(use-package exec-path-from-shell
  :vc (:url "https://github.com/purcell/exec-path-from-shell" :rev :newest)
  :when (or (memq window-system '(mac ns x))
            (unless (memq system-type '(ms-dos windows-nt))
              (daemonp)))
  :custom (exec-path-from-shell-arguments '("-l"))
  :config
  (dolist (var '("GPG_AGENT_INFO" "LANG" "LC_CTYPE"))
    (add-to-list 'exec-path-from-shell-variables var))
  (exec-path-from-shell-initialize))

;;; Long tail

;; General performance tuning
(use-package gcmh
  :ensure t
  :diminish
  :custom
  (gcmh-high-cons-threshold (* 128 1024 1024))
  :hook (after-init . gcmh-mode))

;;; Theme

;;; Dired mode

(use-package dired
  :demand t
  :hook (dired-mode . dired-hide-details-mode)
  :custom
  (dired-dwim-target t)
  (dired-listing-switches "-alGhv --group-directories-first")
  (dired-recursive-copies 'always)
  (dired-kill-when-opening-new-dired-buffer t))

;;; Isearch settings

(use-package isearch
  :custom
  (isearch-lazy-count t)
  (isearch-allow-motion t)
  (isearch-motion-changes-direction t))

;;; Configure uniquification of buffer names

(use-package uniquify
  :custom
  (uniquify-buffer-name-style 'reverse)
  (uniquify-separator " • ")
  (uniquify-after-kill-buffer-p t)
  (uniquify-ignore-buffers-re "^\\*"))

;;; Minibuffer and completion

(use-package minibuffer
  :custom
  (read-file-name-completion-ignore-case t)
  (read-buffer-completion-ignore-case t)
  (completion-ignore-case t)
  (enable-recursive-minibuffers t)
  (inhibit-message-regexps '("^Saving file" "^Wrote"))
  (set-message-functions '(inhibit-message))
  :init (minibuffer-depth-indicate-mode))

(use-package vertico
  :ensure t
  :demand t
  :bind (:map vertico-map
              ([tab] . vertico-next)
              ([backtab] . vertico-previous))
  :custom (vertico-cycle t)
  :config (vertico-mode))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion--category-override '((file (styles basic partial-completion)))))

(use-package marginalia
  :ensure t
  :init (marginalia-mode))

(use-package consult
  :ensure t
  :defer 0.5
  :bind (([remap repeat-complex-command] . consult-complex-command)
         ([remap switch-to-buffer] . consult-buffer)
         ([remap switch-to-buffer-other-window] . consult-buffer-other-window)
         ([remap switch-to-buffer-other-frame] . consult-buffer-other-frame)
         ([remap project-switch-to-buffer] . consult-project-buffer)
         ([remap bookmark-jump] . consult-bookmark)
         ([remap goto-line] . consult-goto-line)
         ([remap imenu] . consult-imenu)
         ([remap yank-pop] . consult-yank-pop)
         ("C-c M-x" . consult-mode-command)
         ("C-c h" . consult-history)
         ("C-c k" . consult-kmacro)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
         ([remap Info-search] . consult-info)
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flymake)
         ("M-g o" . consult-outline)
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-s d" . consult-fd)
         ("M-s D" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-s e" . consult-isearch-history)
         ("M-s l" . consult-line)
         :map minibuffer-local-map
         ("M-s" . consult-history))
  :custom
  (register-preview-delay 0.5)
  (register-preview-function #'consult-register-format)
  (consult-narrow-key "<")
  (xref-search-program 'ripgrep)
  (xref-show-xrefs-function #'consult-xref)
  (xref-show-definitions-function #'consult-xref)
  :commands consult--customize-put
  :init
  (advice-add #'register-preview :override #'consult-register-window)
  :config
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   :preview-key "M-."))

(use-package embark
  :ensure t
  :bind
  ("C-." . embark-act)
  ("M-." . embark-dwim)
  ("C-h b" . embark-bindings)
  ("C-h B" . embark-bindings-at-point)
  ("M-n" . embark-next-symbol)
  ("M-p" . embark-previous-symbol)
  :custom
  (embark-quit-after-action nil)
  (prefix-help-command #'embark-prefix-help-command)
  (embark-indicators '(embark-minimal-indicator
                       embark-highlight-indicator
                       embark-isearch-highlight-indicator))
  (embark-cycle-key ".")
  (embark-help-key "?")
  :config
  (setq embark-candidate-collectors
        (cl-substitute 'embark-sorted-minibuffer-candidates
                       'embark-minibuffer-candidates
                       embark-candidate-collectors)))

(use-package corfu
  :ensure t
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-prefix 1)
  (corfu-auto-delay 0.1)
  (corfu-preselect 'prompt)
  (corfu-on-exact-match nil)
  :bind (:map corfu-map
              ([tab] . corfu-next)
              ([backtab] . corfu-previous)
              ("S-<return>" . corfu-insert)
              ("RET" . nil)
              ([remap move-end-of-line] . nil))
  :hook (eshell-mode . (lambda () (setq-local corfu-auto nil)))
  :init
  (global-corfu-mode)
  (corfu-popupinfo-mode))

(use-package cape
  :ensure t
  :after corfu
  :bind (("C-c p p" . completion-at-point)
         ("C-c p t" . complete-tag)
         ("C-c p d" . cape-dabbrev)
         ("C-c p f" . cape-file)
         ("C-c p s" . cape-elisp-symbol)
         ("C-c p e" . cape-elisp-block)
         ("C-c p a" . cape-abbrev)
         ("C-c p l" . cape-line)
         ("C-c p w" . cape-dict))
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-elisp-block)
  (advice-add 'eglot-completion-at-point :around #'cape-wrap-buster))

(use-package yasnippet
  :ensure t
  :diminish yas-minor-mode
  :custom (yas-keymap-disable-hook
           (lambda () (and (frame-live-p corfu--frame)
                           (frame-visible-p corfu--frame))))
  :hook (after-init . yas-global-mode))

;;; Settings for hippie-expand

(use-package hippie-exp
  :bind ([remap dabbrev-expand] . hippie-expand)
  :custom (hippie-expand-try-functions-list
           '(try-complete-file-name-partially
             try-complete-file-name
             try-expand-dabbrev
             try-expand-dabbrev-all-buffers
             try-expand-dabbrev-from-kill)))

;;; Working with Windows within frames

(use-package window
  :bind (("C-x w r" . rotate-windows)
         ("C-x w C-r" . rotate-windows-back)
         ("C-x w s" . window-swap-states)
         ("C-x w t" . transpose-window-layout)
         ("C-x w h" . flip-window-layout-horizontally)
         ("C-x w v" . flip-window-layout-vertically))

  :custom (split-width-threshold 140))

(use-package winner
  :defer 0.5
  :bind (("M-N" . winner-redo)
         ("M-P" . winner-undo))
  :config (winner-mode 1))

;;; Settings for tracking recent files

(use-package desktop
  :custom
  (desktop-load-locked-desktop 'check-pid)
  (desktop-globals-to-save nil)
  :config (desktop-save-mode 1))

(use-package recentf
  :custom
  (recentf-max-saved-items 1000)
  :config (recentf-mode))

;;; Save and restore editor sessions between restarts

(use-package savehist
  :custom (savehist-additional-variables
           '(last-kbd-macro
             register-alist
             (comint-input-ring        . 50)
             (compile-command          . 20)
             (dired-regexp-history     . 20)
             (face-name-history        . 20)
             (kill-ring                . 20)
             (regexp-search-ring       . 20)
             (search-ring              . 20)))
  :config (savehist-mode))

(use-package saveplace
  :custom (save-place-autosave-interval (* 60 5))
  :config (save-place-mode))

;;; Editing utils

(use-package emacs
  :custom
  (blink-cursor-interval 0.4)
  (delete-by-moving-to-trash t)
  (mouse-yank-at-point t)
  (scroll-preserve-screen-position 'always)
  (truncate-partial-width-windows nil)
  (tooltip-delay 1.5)
  (use-short-answers t)
  (frame-resize-pixelwise t)
  (x-underline-at-descent-line t)
  (create-lockfiles nil)
  (auto-save-default nil)
  (make-backup-files nil)
  (auto-save-visited-interval 1.1)
  (auto-save-visited-predicate
   (lambda ()
     (and (not (buffer-live-p (get-buffer " *vundo tree*")))
          (not (string-suffix-p "gpg" (file-name-extension (buffer-name)) t))
          (not (eq (buffer-base-buffer
                    (get-buffer (concat "CAPTURE-" (buffer-name))))
                   (current-buffer)))
          (or (not (boundp 'corfu--total)) (zerop corfu--total))
          (or (not (boundp 'yas--active-snippets))
              (not yas--active-snippets)))))
  (display-fill-column-indicator-character ?\u254e)
  :hook ((prog-mode . display-fill-column-indicator-mode)
         ((prog-mode text-mode) . indicate-buffer-boundaries-left)
         (after-init . auto-save-visited-mode))
  :config
  (defun indicate-buffer-boundaries-left ()
    (setq indicate-buffer-boundaries 'left)))

(use-package simple
  :bind
  ("M-j" . join-line) ; M-^ is inconvenient, so also bind M-j
  ("C-x x p" . pop-to-mark-command)
  ("C-x C-." . pop-global-mark)
  ([remap capitalize-word] . capitalize-dwim)
  ("<f8>" . scratch-buffer)
  :custom
  (save-interprogram-paste-before-kill t)
  (set-mark-command-repeat-pop t)
  (read-extended-command-predicate #'command-completion-default-include-p)
  :config
  (column-number-mode t))

(use-package pixel-scroll
  :config (pixel-scroll-precision-mode t))

(use-package delsel
  :config (delete-selection-mode))

(use-package elec-pair
  :config (electric-pair-mode))

(use-package electric
  :config (electric-indent-mode))

(use-package autorevert
  :diminish
  :custom (auto-revert-verbose nil)
  :config (global-auto-revert-mode))

(use-package highlight-escape-sequences
  :ensure t
  :hook (after-init . hes-mode))

(use-package symbol-overlay
  :vc (:url "https://github.com/wolray/symbol-overlay" :rev :latest)
  :diminish
  :hook ((prog-mode html-mode conf-mode) . symbol-overlay-mode)
  :bind (:map symbol-overlay-mode-map
              ("M-i" . symbol-overlay-put)
              ("M-I" . symbol-overlay-remove-all)
              ("M-n" . symbol-overlay-jump-next)
              ("M-p" . symbol-overlay-jump-prev)))

;;; Version control

(use-package diff-hl
  :ensure t
  :bind (:map diff-hl-mode-map
              ("<left-fringe> <mouse-1>" . diff-hl-diff-goto-hunk)
              ("M-]" . diff-hl-next-hunk)
              ("M-[" . diff-hl-previous-hunk))
  :hook ((after-init . global-diff-hl-mode)
         (dired-mode . diff-hl-dired-mode))
  :commands diff-hl-magit-post-refresh
  :config
  (with-eval-after-load 'magit
    (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)))

(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status)
  :custom
  (magit-diff-refine-hunk t)
  (magit-module-sections-nested nil)
  (magit-display-buffer-function
   #'magit-display-buffer-same-window-except-diff-v1)
  (magit-bury-buffer-function 'magit-restore-window-configuration)
  :init
  (defmacro aquamacs/fullframe-mode (mode)
    "Configure buffers that open in MODE to start out full-frame."
    `(add-to-list 'display-buffer-alist
                  (cons (cons 'major-mode ,mode)
                        (list 'display-buffer-full-frame))))
  (aquamacs/fullframe-mode 'magit-status-mode)
  :commands magit-add-section-hook
  :config
  (put 'magit-clean 'disabled nil)
  (magit-add-section-hook 'magit-status-sections-hook
                          'magit-insert-modules
                          'magit-insert-unpulled-from-upstream)
  (with-eval-after-load "magit-submodule"
    (dolist (module-section '(magit-insert-modules-unpulled-from-pushremote
                              magit-insert-modules-unpushed-to-upstream
                              magit-insert-modules-unpushed-to-pushremote))
      (remove-hook 'magit-module-sections-hook module-section))))

;;; Text editing

(use-package org
  :bind (("C-c l" . org-store-link)
         ("C-c c" . org-capture)
         :map org-mode-map
         ("C-c v" . visible-mode)
         ("C-c e d" . org-pandoc-convert-to-docx)
         :map sanityinc/org-global-prefix-map
         ("j" . org-clock-goto)
         ("l" . org-clock-in-last)
         ("i" . org-clock-in)
         ("o" . org-clock-out)
         ("b" . org-mark-ring-goto)
         :map org-src-mode-map
         ("C-c C-c" . org-edit-src-exit))
  :bind-keymap ("C-c o" . sanityinc/org-global-prefix-map)
  :hook (org-mode . variable-pitch-mode)
  :custom
  (org-modules nil) ; Faster loading
  (org-log-done 'time)
  (org-log-into-drawer t)
  (org-fontify-done-headline nil)
  (org-edit-timestamp-down-means-later t)
  (org-export-coding-system 'utf-8)
  (org-fast-tag-selection-single-key 'expert)
  (org-html-validation-link nil)
  (org-export-kill-product-buffer-when-displayed t)
  (org-tags-column 80)
  (org-hide-emphasis-markers t)
  (org-confirm-babel-evaluate nil)
  (org-link-elisp-confirm-function nil)
  (org-src-preserve-indentation t)
  (org-directory "~/agenda")
  (org-default-notes-file (expand-file-name "inbox.org" org-directory))
  (org-agenda-files (list "inbox.org" "agenda.org" "notes.org" "projects.org"))
  (org-capture-templates
   `(("i" "Inbox" entry  (file "") ; "" => `org-default-notes-file'
      ,(concat "* TODO %?\n"
               "/Entered on/ %U"))
     ("m" "Meeting" entry  (file+headline "agenda.org" "Future")
      ,(concat "* %? :meeting:\n"
               "<%<%Y-%m-%d %a %H:00>>"))
     ("n" "Note" entry  (file "notes.org")
      ,(concat "* Note (%a)\n"
               "/Entered on/ %U\n" "\n" "%?"))))
  ;; (org-capture-mode-hook 'delete-other-windows)
  (org-todo-keywords
   '((sequence "TODO(t)" "NEXT(n)" "HOLD(h)" "|" "DONE(d!/!)")))
  (org-todo-repeat-to-state "NEXT")
  (org-todo-keyword-faces '(("NEXT" :inherit warning)))
  (org-archive-location "%s_archive::* Archive")
  :commands (org-get-todo-state org-entry-get org-entry-put)
  :config
  (custom-theme-set-faces
   'user
   '(org-block ((t (:inherit fixed-pitch))))
   '(org-code ((t (:inherit (shadow fixed-pitch)))))
   '(org-document-info-keyword ((t (:inherit (shadow fixed-pitch)))))
   '(org-indent ((t (:inherit (org-hide fixed-pitch)))))
   '(org-meta-line ((t (:inherit (font-lock-comment-face fixed-pitch)))))
   '(org-property-value ((t (:inherit fixed-pitch))))
   '(org-special-keyword ((t (:inherit (font-lock-comment-face fixed-pitch)))))
   '(org-table ((t (:inherit fixed-pitch))))
   '(org-tag ((t (:inherit (shadow fixed-pitch) :weight bold :height 1.0))))
   '(org-verbatim ((t (:inherit (shadow fixed-pitch))))))
  
  (advice-add 'org-babel-execute-src-block
              :before #'my/org-babel-execute-src-block)
  (add-hook 'org-after-todo-state-change-hook #'log-todo-next-creation-date)
  (defun org-capture-inbox ()
    (interactive)
    (call-interactively 'org-store-link)
    (org-capture nil "i"))
  :preface
  (defun log-todo-next-creation-date ()
    "Log NEXT creation time in the property drawer under key \\='ACTIVATED\\='"
    (when (and (string= (org-get-todo-state) "NEXT")
               (not (org-entry-get nil "ACTIVATED")))
      (org-entry-put nil "ACTIVATED" (format-time-string "[%Y-%m-%d]"))))
  
  (defvar sanityinc/org-global-prefix-map (make-sparse-keymap)
    "A keymap for handy global access to org helpers, particularly clocking.")

  (defun my/org-babel-execute-src-block (&optional _arg info _params)
    "Load language when needed"
    (let* ((lang (nth 0 info))
           (sym (if (member (downcase lang) '("c" "cpp" "c++"))
                    'C (intern lang)))
           (backup-languages org-babel-load-languages))
      (unless (assoc sym backup-languages)
        (condition-case err
            (progn
              (org-babel-do-load-languages 'org-babel-load-languages
                                           (list (cons sym t)))
              (setq-default org-babel-load-languages
                            (append (list (cons sym t)) backup-languages)))
          (file-missing
           (setq-default org-babel-load-languages backup-languages)
           err)))))

  (defun org-pandoc-convert-to-docx ()
    "Convert current buffer file to docx format by Pandoc."
    (interactive)
    (let ((command "pandoc")
          (refdoc (list "--reference-doc"
                        (expand-file-name
                         "var/reference.docx" user-emacs-directory))))
      (cond
       ((not buffer-file-name) (user-error "Must be visiting a file"))
       (t (let* ((buffer (generate-new-buffer " *Pandoc output*"))
                 (filename (list buffer-file-name))
                 (output (list "-o"
                               (concat
                                (file-name-sans-extension (buffer-file-name))
                                ".docx")))
                 (arguments (nconc filename refdoc output))
                 (exit-code (apply
                             #'call-process
                             command nil buffer nil arguments)))
            (cond
             ((eql 0 exit-code)
              (kill-buffer buffer)
              (message "Convert finished: %s" (cadr output)))
             (t (with-current-buffer buffer
                  (goto-char (point-min))
                  (insert (format "%s\n%s\n\n" (make-string 50 ?=)
                                  (current-time-string)))
                  (insert (format
                           "Called pandoc with:\n\n%s\n\n Error:\n\n"
                           (mapconcat #'identity (cons command arguments)
                                      " ")))
                  (special-mode))
                (pop-to-buffer buffer)
                (error "Convert failed with exit code %s" exit-code)))))))))

(use-package org-refile
  :after org
  :custom
  (org-refile-targets '((nil :maxlevel . 5) (org-agenda-files :maxlevel . 5)))
  (org-refile-use-outline-path t)
  (org-outline-path-complete-in-steps nil)
  (org-refile-allow-creating-parent-nodes 'confirm))

(use-package org-agenda
  :bind ("C-c a" . org-agenda)
  :hook (org-agenda-mode . (lambda ()
                             (add-hook
                              'window-configuration-change-hook
                              'org-agenda-align-tags nil t)))
  :hook (org-agenda-mode . hl-line-mode)
  :custom
  (org-agenda-clockreport-parameter-plist '(:link t :maxlevel 3))
  (org-agenda-compact-blocks t)
  (org-agenda-sticky t)
  (org-agenda-start-on-weekday nil)
  (org-agenda-span 'day)
  (org-agenda-window-setup 'current-window)
  (org-agenda-custom-commands
   '(("n" "Notes" tags "notes"
      ((org-agenda-overriding-header "Notes")
       (org-tags-match-list-sublevels t)))
     ("g" "Get Things Done (GTD)"
      ((agenda ""
               ((org-agenda-skip-function
                 '(org-agenda-skip-entry-if 'deadline))
                (org-deadline-warning-days 0)))
       (todo "NEXT"
             ((org-agenda-skip-function
               '(org-agenda-skip-entry-if 'deadline))
              (org-agenda-prefix-format " %i %-2:c [%e] ")
              (org-agenda-overriding-header "Tasks")))
       (agenda nil
               ((org-agenda-entry-types '(:deadline))
                (org-agenda-format-date "")
                (org-deadline-warning-days 7)
                (org-agenda-skip-function
                 '(org-agenda-skip-entry-if 'notregexp "\\* NEXT"))
                (org-agenda-overriding-header "Deadlines")))
       (tags-todo "inbox"
                  ((org-agenda-prefix-format "  %?-12t% s")
                   (org-agenda-overriding-header "Inbox")))
       (tags "CLOSED>=\"<today>\""
             ((org-agenda-overriding-header "Completed today"))))))))


;;; Programming languages support

;;; Built-in packages

(use-package eldoc
  :custom (eldoc-documentation-strategy #'eldoc-documentation-compose)
  :config (eldoc-add-command-completions "paredit-"))

(use-package help
  :defer t
  :custom (help-window-select t)
  :config (temp-buffer-resize-mode))

(use-package info
  :hook ((Info-mode . variable-pitch-mode)
         (Info-mode . writeroom-mode))
  :custom-face (Info-quoted ((t (:inherit fixed-pitch)))))

(use-package text-mode
  :custom (text-mode-ispell-word-completion nil))

;;; Tequila worms

(progn ; `startup'
  (message "Loading %s...done (%.3fs)" user-init-file
           (float-time (time-subtract (current-time)
                                      before-user-init-time)))
  (add-hook 'after-init-hook
            (lambda ()
              (message
               "Loading %s...done (%.3fs) [after-init]" user-init-file
               (float-time (time-subtract (current-time)
                                          before-user-init-time))))
            t))

;; Local Variables:
;; indent-tabs-mode: nil
;; no-byte-compile: nil
;; End:
;;; init.el ends here
