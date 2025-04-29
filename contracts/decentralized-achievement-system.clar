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
