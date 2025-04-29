;; Personal Achievement  System
;; This blockchain-powered contract enables decentralized management of personal tasks and achievements.
;; Each achievement entry consists of task information and completion indicators with deadline functionality.

;; Error response constants for improved user experience
(define-constant ERR-ENTRY-DOESNT-EXIST (err u404))
(define-constant ERR-ENTRY-ALREADY-EXISTS (err u409))
(define-constant ERR-INVALID-PARAMETERS (err u400))

;; Primary storage for achievement entries
;; Links blockchain identities to their achievement records
(define-map achievement-registry
    principal
    {
        task-content: (string-ascii 100),
        is-completed: bool
    }
)

;; Secondary storage for achievement scheduling
;; Manages time-based constraints for achievement completion
(define-map achievement-time-constraints
    principal
    {
        target-height: uint,
        notification-delivered: bool
    }
)

;; Achievement prioritization classification storage
;; Enables importance-based organization of achievements
(define-map achievement-importance
    principal
    {
        importance-tier: uint
    }
)

;; Comprehensive achievement information retrieval
;; Returns both content and completion status in single transaction
(define-read-only (fetch-achievement-data (blockchain-identity principal))
    (match (map-get? achievement-registry blockchain-identity)
        entry-data (ok {
            task-content: (get task-content entry-data),
            is-completed: (get is-completed entry-data)
        })
        ERR-ENTRY-DOESNT-EXIST
    )
)

;; Public function to create a new achievement entry
;; Establishes initial record with incomplete status
(define-public (create-achievement 
    (task-content (string-ascii 100)))
    (let
        (
            (blockchain-identity tx-sender)
            (existing-entry (map-get? achievement-registry blockchain-identity))
        )
        (if (is-none existing-entry)
            (begin
                (if (is-eq task-content "")
                    (err ERR-INVALID-PARAMETERS)
                    (begin
                        (map-set achievement-registry blockchain-identity
                            {
                                task-content: task-content,
                                is-completed: false
                            }
                        )
                        (ok "Achievement entry successfully created.")
                    )
                )
            )
            (err ERR-ENTRY-ALREADY-EXISTS)
        )
    )
)

;; Public function to update existing achievement details
;; Allows modification of both content and completion status
(define-public (update-achievement
    (task-content (string-ascii 100))
    (is-completed bool))
    (let
        (
            (blockchain-identity tx-sender)
            (existing-entry (map-get? achievement-registry blockchain-identity))
        )
        (if (is-some existing-entry)
            (begin
                (if (is-eq task-content "")
                    (err ERR-INVALID-PARAMETERS)
                    (begin
                        (if (or (is-eq is-completed true) (is-eq is-completed false))
                            (begin
                                (map-set achievement-registry blockchain-identity
                                    {
                                        task-content: task-content,
                                        is-completed: is-completed
                                    }
                                )
                                (ok "Achievement entry successfully updated.")
                            )
                            (err ERR-INVALID-PARAMETERS)
                        )
                    )
                )
            )
            (err ERR-ENTRY-DOESNT-EXIST)
        )
    )
)

;; Public function to establish achievement time constraints
;; Sets blockchain height-based deadline for achievement completion
(define-public (establish-achievement-deadline (blocks-until-deadline uint))
    (let
        (
            (blockchain-identity tx-sender)
            (existing-entry (map-get? achievement-registry blockchain-identity))
            (deadline-block-height (+ block-height blocks-until-deadline))
        )
        (if (is-some existing-entry)
            (if (> blocks-until-deadline u0)
                (begin
                    (map-set achievement-time-constraints blockchain-identity
                        {
                            target-height: deadline-block-height,
                            notification-delivered: false
                        }
                    )
                    (ok "Achievement deadline successfully established.")
                )
                (err ERR-INVALID-PARAMETERS)
            )
            (err ERR-ENTRY-DOESNT-EXIST)
        )
    )
)

;; Public function to delegate achievements to other blockchain identities
;; Enables collaborative achievement management
(define-public (delegate-achievement
    (recipient-identity principal)
    (task-content (string-ascii 100)))
    (let
        (
            (existing-entry (map-get? achievement-registry recipient-identity))
        )
        (if (is-none existing-entry)
            (begin
                (if (is-eq task-content "")
                    (err ERR-INVALID-PARAMETERS)
                    (begin
                        (map-set achievement-registry recipient-identity
                            {
                                task-content: task-content,
                                is-completed: false
                            }
                        )
                        (ok "Achievement successfully delegated.")
                    )
                )
            )
            (err ERR-ENTRY-ALREADY-EXISTS)
        )
    )
)

;; Public function to establish achievement priority classification
;; Supports multi-tier prioritization system (tiers 1-3)
(define-public (configure-achievement-importance (importance-tier uint))
    (let
        (
            (blockchain-identity tx-sender)
            (existing-entry (map-get? achievement-registry blockchain-identity))
        )
        (if (is-some existing-entry)
            (if (and (>= importance-tier u1) (<= importance-tier u3))
                (begin
                    (map-set achievement-importance blockchain-identity
                        {
                            importance-tier: importance-tier
                        }
                    )
                    (ok "Achievement importance successfully configured.")
                )
                (err ERR-INVALID-PARAMETERS)
            )
            (err ERR-ENTRY-DOESNT-EXIST)
        )
    )
)

;; Public function to validate existing achievement entry
;; Performs non-destructive verification before operations
(define-public (validate-achievement-entry)
    (let
        (
            (blockchain-identity tx-sender)
            (existing-entry (map-get? achievement-registry blockchain-identity))
        )
        (if (is-some existing-entry)
            (let
                (
                    (current-entry (unwrap! existing-entry ERR-ENTRY-DOESNT-EXIST))
                    (entry-content (get task-content current-entry))
                    (entry-status (get is-completed current-entry))
                )
                (ok {
                    exists: true,
                    content-length: (len entry-content),
                    is-finished: entry-status
                })
            )
            (ok {
                exists: false,
                content-length: u0,
                is-finished: false
            })
        )
    )
)

;; Public function to remove achievement entry
;; Allows users to clear their achievement records
(define-public (remove-achievement)
    (let
        (
            (blockchain-identity tx-sender)
            (existing-entry (map-get? achievement-registry blockchain-identity))
        )
        (if (is-some existing-entry)
            (begin
                (map-delete achievement-registry blockchain-identity)
                (ok "Achievement successfully removed.")
            )
            (err ERR-ENTRY-DOESNT-EXIST)
        )
    )
)

;; Read-only function to query achievement status
;; Returns boolean completion status for specified identity
(define-read-only (check-achievement-status (blockchain-identity principal))
    (match (map-get? achievement-registry blockchain-identity)
        entry-data (ok (get is-completed entry-data))
        ERR-ENTRY-DOESNT-EXIST
    )
)

