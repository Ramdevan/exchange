class InitMigration < ActiveRecord::Migration
  def change
    create_table "account_versions", force: :cascade do |t|
      t.integer  "member_id",       limit: 4
      t.integer  "account_id",      limit: 4
      t.integer  "reason",          limit: 4
      t.decimal  "balance",                     precision: 32, scale: 16
      t.decimal  "locked",                      precision: 32, scale: 16
      t.decimal  "fee",                         precision: 32, scale: 16
      t.decimal  "amount",                      precision: 32, scale: 16
      t.integer  "modifiable_id",   limit: 4
      t.string   "modifiable_type", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "currency",        limit: 4
      t.integer  "fun",             limit: 4
    end

    add_index "account_versions", ["account_id", "reason"], name: "index_account_versions_on_account_id_and_reason", using: :btree
    add_index "account_versions", ["account_id"], name: "index_account_versions_on_account_id", using: :btree
    add_index "account_versions", ["member_id", "reason"], name: "index_account_versions_on_member_id_and_reason", using: :btree
    add_index "account_versions", ["modifiable_id", "modifiable_type"], name: "index_account_versions_on_modifiable_id_and_modifiable_type", using: :btree

    create_table "accounts", force: :cascade do |t|
      t.integer  "member_id",                       limit: 4
      t.integer  "currency",                        limit: 4
      t.decimal  "balance",                                   precision: 32, scale: 16
      t.decimal  "locked",                                    precision: 32, scale: 16
      t.datetime "created_at"
      t.datetime "updated_at"
      t.decimal  "in",                                        precision: 32, scale: 16
      t.decimal  "out",                                       precision: 32, scale: 16
      t.integer  "default_withdraw_fund_source_id", limit: 4
      t.decimal  "referral_commissions",                      precision: 32, scale: 16, default: 0.0
    end

    add_index "accounts", ["member_id", "currency"], name: "index_accounts_on_member_id_and_currency", using: :btree
    add_index "accounts", ["member_id"], name: "index_accounts_on_member_id", using: :btree

    create_table "api_tokens", force: :cascade do |t|
      t.integer  "member_id",             limit: 4,                   null: false
      t.string   "access_key",            limit: 50,                  null: false
      t.string   "secret_key",            limit: 50,                  null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "trusted_ip_list",       limit: 255
      t.string   "label",                 limit: 255
      t.integer  "oauth_access_token_id", limit: 4
      t.datetime "expire_at"
      t.string   "scopes",                limit: 255
      t.datetime "deleted_at"
      t.string   "api_type",              limit: 255, default: "web"
    end

    add_index "api_tokens", ["access_key"], name: "index_api_tokens_on_access_key", unique: true, using: :btree
    add_index "api_tokens", ["secret_key"], name: "index_api_tokens_on_secret_key", unique: true, using: :btree

    create_table "assets", force: :cascade do |t|
      t.string  "type",            limit: 255
      t.integer "attachable_id",   limit: 4
      t.string  "attachable_type", limit: 255
      t.string  "file",            limit: 255
    end

    create_table "audit_logs", force: :cascade do |t|
      t.string   "type",           limit: 255
      t.integer  "operator_id",    limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "auditable_id",   limit: 4
      t.string   "auditable_type", limit: 255
      t.string   "source_state",   limit: 255
      t.string   "target_state",   limit: 255
    end

    add_index "audit_logs", ["auditable_id", "auditable_type"], name: "index_audit_logs_on_auditable_id_and_auditable_type", using: :btree
    add_index "audit_logs", ["operator_id"], name: "index_audit_logs_on_operator_id", using: :btree

    create_table "authentications", force: :cascade do |t|
      t.string   "provider",   limit: 255
      t.string   "uid",        limit: 255
      t.string   "token",      limit: 255
      t.string   "secret",     limit: 255
      t.integer  "member_id",  limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "nickname",   limit: 255
    end

    add_index "authentications", ["member_id"], name: "index_authentications_on_member_id", using: :btree
    add_index "authentications", ["provider", "uid"], name: "index_authentications_on_provider_and_uid", using: :btree

    create_table "comments", force: :cascade do |t|
      t.text     "content",    limit: 65535
      t.integer  "author_id",  limit: 4
      t.integer  "ticket_id",  limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "deposits", force: :cascade do |t|
      t.integer  "account_id",             limit: 4
      t.integer  "member_id",              limit: 4
      t.integer  "currency",               limit: 4
      t.decimal  "amount",                             precision: 32, scale: 16
      t.decimal  "fee",                                precision: 32, scale: 16
      t.string   "fund_uid",               limit: 255
      t.string   "fund_extra",             limit: 255
      t.string   "txid",                   limit: 255
      t.integer  "state",                  limit: 4
      t.string   "aasm_state",             limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "done_at"
      t.string   "confirmations",          limit: 255
      t.string   "type",                   limit: 255
      t.integer  "payment_transaction_id", limit: 4
      t.integer  "txout",                  limit: 4
    end

    add_index "deposits", ["txid", "txout"], name: "index_deposits_on_txid_and_txout", using: :btree

    create_table "document_translations", force: :cascade do |t|
      t.integer  "document_id", limit: 4,     null: false
      t.string   "locale",      limit: 255,   null: false
      t.datetime "created_at",                null: false
      t.datetime "updated_at",                null: false
      t.string   "title",       limit: 255
      t.text     "body",        limit: 65535
      t.text     "desc",        limit: 65535
      t.text     "keywords",    limit: 65535
    end

    add_index "document_translations", ["document_id"], name: "index_document_translations_on_document_id", using: :btree
    add_index "document_translations", ["locale"], name: "index_document_translations_on_locale", using: :btree

    create_table "documents", force: :cascade do |t|
      t.string   "key",        limit: 255
      t.string   "title",      limit: 255
      t.text     "body",       limit: 65535
      t.boolean  "is_auth"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "desc",       limit: 65535
      t.text     "keywords",   limit: 65535
    end

    create_table "exchange_commissions", force: :cascade do |t|
      t.string   "commission_type", limit: 255
      t.decimal  "percentage",                  precision: 8, scale: 4, default: 0.0
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "fees", force: :cascade do |t|
      t.decimal  "min",        precision: 15, scale: 4
      t.decimal  "max",        precision: 15, scale: 4
      t.decimal  "taker",      precision: 8,  scale: 4, default: 0.0
      t.decimal  "maker",      precision: 8,  scale: 4, default: 0.0
      t.datetime "created_at",                                        null: false
      t.datetime "updated_at",                                        null: false
    end

    create_table "fund_sources", force: :cascade do |t|
      t.integer  "member_id",       limit: 4
      t.integer  "currency",        limit: 4
      t.string   "extra",           limit: 255
      t.string   "uid",             limit: 255
      t.boolean  "is_locked",                   default: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "deleted_at"
      t.string   "destination_tag", limit: 255
    end

    create_table "holder_discounts", force: :cascade do |t|
      t.decimal  "min",        precision: 15, scale: 4
      t.decimal  "max",        precision: 15, scale: 4
      t.decimal  "percent",    precision: 4,  scale: 2
      t.datetime "created_at",                          null: false
      t.datetime "updated_at",                          null: false
    end

    create_table "id_documents", force: :cascade do |t|
      t.integer  "id_document_type",   limit: 4
      t.string   "name",               limit: 255
      t.string   "id_document_number", limit: 255
      t.integer  "member_id",          limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
      t.date     "birth_date"
      t.text     "address",            limit: 65535
      t.string   "city",               limit: 255
      t.string   "country",            limit: 255
      t.string   "zipcode",            limit: 255
      t.integer  "id_bill_type",       limit: 4
      t.string   "aasm_state",         limit: 255
      t.text     "note",               limit: 65535
    end

    create_table "identities", force: :cascade do |t|
      t.string   "email",           limit: 255
      t.string   "password_digest", limit: 255
      t.boolean  "is_active"
      t.integer  "retry_count",     limit: 4
      t.boolean  "is_locked"
      t.datetime "locked_at"
      t.datetime "last_verify_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "liquidity_histories", force: :cascade do |t|
      t.integer  "liquidity_status_id", limit: 4
      t.text     "detail",              limit: 65535
      t.datetime "created_at",                        null: false
      t.datetime "updated_at",                        null: false
    end

    create_table "liquidity_statuses", force: :cascade do |t|
      t.integer  "order_id",   limit: 4
      t.integer  "liquid_id",  limit: 4
      t.string   "state",      limit: 255
      t.datetime "created_at",             null: false
      t.datetime "updated_at",             null: false
    end

    add_index "liquidity_statuses", ["order_id"], name: "index_liquidity_statuses_on_order_id", unique: true, using: :btree

    create_table "members", force: :cascade do |t|
      t.string   "sn",                    limit: 255
      t.string   "display_name",          limit: 255
      t.string   "email",                 limit: 255
      t.integer  "identity_id",           limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "state",                 limit: 4
      t.boolean  "activated"
      t.integer  "country_code",          limit: 4
      t.string   "phone_number",          limit: 255
      t.boolean  "disabled",                                                   default: false
      t.boolean  "api_disabled",                                               default: false
      t.string   "nickname",              limit: 255
      t.string   "referral_code",         limit: 255
      t.integer  "referred_by_id",        limit: 4
      t.datetime "referral_completed_at"
      t.integer  "referral_count",        limit: 4,                            default: 0
      t.decimal  "trade_volume",                      precision: 16, scale: 2, default: 0.0
    end

    create_table "oauth_access_grants", force: :cascade do |t|
      t.integer  "resource_owner_id", limit: 4,     null: false
      t.integer  "application_id",    limit: 4,     null: false
      t.string   "token",             limit: 255,   null: false
      t.integer  "expires_in",        limit: 4,     null: false
      t.text     "redirect_uri",      limit: 65535, null: false
      t.datetime "created_at",                      null: false
      t.datetime "revoked_at"
      t.string   "scopes",            limit: 255
    end

    add_index "oauth_access_grants", ["token"], name: "index_oauth_access_grants_on_token", unique: true, using: :btree

    create_table "oauth_access_tokens", force: :cascade do |t|
      t.integer  "resource_owner_id", limit: 4
      t.integer  "application_id",    limit: 4
      t.string   "token",             limit: 255, null: false
      t.string   "refresh_token",     limit: 255
      t.integer  "expires_in",        limit: 4
      t.datetime "revoked_at"
      t.datetime "created_at",                    null: false
      t.string   "scopes",            limit: 255
      t.datetime "deleted_at"
    end

    add_index "oauth_access_tokens", ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, using: :btree
    add_index "oauth_access_tokens", ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id", using: :btree
    add_index "oauth_access_tokens", ["token"], name: "index_oauth_access_tokens_on_token", unique: true, using: :btree

    create_table "oauth_applications", force: :cascade do |t|
      t.string   "name",         limit: 255,   null: false
      t.string   "uid",          limit: 255,   null: false
      t.string   "secret",       limit: 255,   null: false
      t.text     "redirect_uri", limit: 65535, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "oauth_applications", ["uid"], name: "index_oauth_applications_on_uid", unique: true, using: :btree

    create_table "orders", force: :cascade do |t|
      t.integer  "bid",            limit: 4
      t.integer  "ask",            limit: 4
      t.integer  "currency",       limit: 4
      t.decimal  "price",                      precision: 32, scale: 16
      t.decimal  "volume",                     precision: 32, scale: 16
      t.decimal  "origin_volume",              precision: 32, scale: 16
      t.integer  "state",          limit: 4
      t.datetime "done_at"
      t.string   "type",           limit: 8
      t.integer  "member_id",      limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "sn",             limit: 255
      t.string   "source",         limit: 255,                                         null: false
      t.string   "ord_type",       limit: 10
      t.decimal  "locked",                     precision: 32, scale: 16
      t.decimal  "origin_locked",              precision: 32, scale: 16
      t.decimal  "funds_received",             precision: 32, scale: 16, default: 0.0
      t.integer  "trades_count",   limit: 4,                             default: 0
    end

    add_index "orders", ["currency", "state"], name: "index_orders_on_currency_and_state", using: :btree
    add_index "orders", ["member_id", "state"], name: "index_orders_on_member_id_and_state", using: :btree
    add_index "orders", ["member_id"], name: "index_orders_on_member_id", using: :btree
    add_index "orders", ["state"], name: "index_orders_on_state", using: :btree

    create_table "partial_trees", force: :cascade do |t|
      t.integer  "proof_id",   limit: 4,     null: false
      t.integer  "account_id", limit: 4,     null: false
      t.text     "json",       limit: 65535, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "sum",        limit: 255
    end

    create_table "payment_addresses", force: :cascade do |t|
      t.integer  "account_id", limit: 4
      t.string   "address",    limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "currency",   limit: 4
      t.string   "secret",     limit: 255
      t.string   "details",    limit: 255
    end

    create_table "payment_transactions", force: :cascade do |t|
      t.string   "txid",          limit: 255
      t.decimal  "amount",                    precision: 32, scale: 16
      t.integer  "confirmations", limit: 4
      t.string   "address",       limit: 255
      t.integer  "state",         limit: 4
      t.string   "aasm_state",    limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "receive_at"
      t.datetime "dont_at"
      t.integer  "currency",      limit: 4
      t.string   "type",          limit: 60
      t.integer  "txout",         limit: 4
    end

    add_index "payment_transactions", ["txid", "txout"], name: "index_payment_transactions_on_txid_and_txout", using: :btree
    add_index "payment_transactions", ["type"], name: "index_payment_transactions_on_type", using: :btree

    create_table "proofs", force: :cascade do |t|
      t.string   "root",            limit: 255
      t.integer  "currency",        limit: 4
      t.boolean  "ready",                         default: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "sum",             limit: 255
      t.text     "addresses",       limit: 65535
      t.string   "balance",         limit: 30
      t.string   "destination_tag", limit: 255
    end

    create_table "read_marks", force: :cascade do |t|
      t.integer  "readable_id",   limit: 4
      t.integer  "member_id",     limit: 4,  null: false
      t.string   "readable_type", limit: 20, null: false
      t.datetime "timestamp"
    end

    add_index "read_marks", ["member_id"], name: "index_read_marks_on_member_id", using: :btree
    add_index "read_marks", ["readable_type", "readable_id"], name: "index_read_marks_on_readable_type_and_readable_id", using: :btree

    create_table "referral_commissions", force: :cascade do |t|
      t.integer  "min",         limit: 4
      t.integer  "max",         limit: 4
      t.integer  "fee_percent", limit: 4
      t.datetime "created_at",            null: false
      t.datetime "updated_at",            null: false
    end

    create_table "running_accounts", force: :cascade do |t|
      t.integer  "category",    limit: 4
      t.decimal  "income",                  precision: 32, scale: 16, default: 0.0, null: false
      t.decimal  "expenses",                precision: 32, scale: 16, default: 0.0, null: false
      t.integer  "currency",    limit: 4
      t.integer  "member_id",   limit: 4
      t.integer  "source_id",   limit: 4
      t.string   "source_type", limit: 255
      t.string   "note",        limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "running_accounts", ["member_id"], name: "index_running_accounts_on_member_id", using: :btree
    add_index "running_accounts", ["source_type", "source_id"], name: "index_running_accounts_on_source_type_and_source_id", using: :btree

    create_table "signup_histories", force: :cascade do |t|
      t.integer  "member_id",       limit: 4
      t.string   "ip",              limit: 255
      t.string   "accept_language", limit: 255
      t.string   "ua",              limit: 255
      t.datetime "created_at"
    end

    add_index "signup_histories", ["member_id"], name: "index_signup_histories_on_member_id", using: :btree

    create_table "simple_captcha_data", force: :cascade do |t|
      t.string   "key",        limit: 40
      t.string   "value",      limit: 6
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "simple_captcha_data", ["key"], name: "idx_key", using: :btree

    create_table "taggings", force: :cascade do |t|
      t.integer  "tag_id",        limit: 4
      t.integer  "taggable_id",   limit: 4
      t.string   "taggable_type", limit: 255
      t.integer  "tagger_id",     limit: 4
      t.string   "tagger_type",   limit: 255
      t.string   "context",       limit: 128
      t.datetime "created_at"
    end

    add_index "taggings", ["context"], name: "index_taggings_on_context", using: :btree
    add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
    add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
    add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree
    add_index "taggings", ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy", using: :btree
    add_index "taggings", ["taggable_id"], name: "index_taggings_on_taggable_id", using: :btree
    add_index "taggings", ["taggable_type"], name: "index_taggings_on_taggable_type", using: :btree
    add_index "taggings", ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type", using: :btree
    add_index "taggings", ["tagger_id"], name: "index_taggings_on_tagger_id", using: :btree

    create_table "tags", force: :cascade do |t|
      t.string  "name",           limit: 255
      t.integer "taggings_count", limit: 4,   default: 0
    end

    add_index "tags", ["name"], name: "index_tags_on_name", unique: true, using: :btree

    create_table "tickets", force: :cascade do |t|
      t.string   "title",      limit: 255
      t.text     "content",    limit: 65535
      t.string   "aasm_state", limit: 255
      t.integer  "author_id",  limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "tokens", force: :cascade do |t|
      t.string   "token",      limit: 255
      t.datetime "expire_at"
      t.integer  "member_id",  limit: 4
      t.boolean  "is_used",                default: false
      t.string   "type",       limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "tokens", ["type", "token", "expire_at", "is_used"], name: "index_tokens_on_type_and_token_and_expire_at_and_is_used", using: :btree

    create_table "trades", force: :cascade do |t|
      t.decimal  "price",                            precision: 32, scale: 16
      t.decimal  "volume",                           precision: 32, scale: 16
      t.integer  "ask_id",                 limit: 4
      t.integer  "bid_id",                 limit: 4
      t.integer  "trend",                  limit: 4
      t.integer  "currency",               limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "ask_member_id",          limit: 4
      t.integer  "bid_member_id",          limit: 4
      t.decimal  "funds",                            precision: 32, scale: 16
      t.integer  "fetch_since_kraken_api", limit: 8
      t.integer  "fetch_since_binance_id", limit: 8
    end

    add_index "trades", ["ask_id"], name: "index_trades_on_ask_id", using: :btree
    add_index "trades", ["ask_member_id"], name: "index_trades_on_ask_member_id", using: :btree
    add_index "trades", ["bid_id"], name: "index_trades_on_bid_id", using: :btree
    add_index "trades", ["bid_member_id"], name: "index_trades_on_bid_member_id", using: :btree
    add_index "trades", ["created_at"], name: "index_trades_on_created_at", using: :btree
    add_index "trades", ["currency"], name: "index_trades_on_currency", using: :btree

    create_table "two_factors", force: :cascade do |t|
      t.integer  "member_id",      limit: 4
      t.string   "otp_secret",     limit: 255
      t.datetime "last_verify_at"
      t.boolean  "activated"
      t.string   "type",           limit: 255
      t.datetime "refreshed_at"
    end

    create_table "versions", force: :cascade do |t|
      t.string   "item_type",  limit: 255,   null: false
      t.integer  "item_id",    limit: 4,     null: false
      t.string   "event",      limit: 255,   null: false
      t.string   "whodunnit",  limit: 255
      t.text     "object",     limit: 65535
      t.datetime "created_at"
    end

    add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

    create_table "withdraws", force: :cascade do |t|
      t.string   "sn",         limit: 255
      t.integer  "account_id", limit: 4
      t.integer  "member_id",  limit: 4
      t.integer  "currency",   limit: 4
      t.decimal  "amount",                 precision: 32, scale: 16
      t.decimal  "fee",                    precision: 32, scale: 16
      t.string   "fund_uid",   limit: 255
      t.string   "fund_extra", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "done_at"
      t.string   "txid",       limit: 255
      t.string   "aasm_state", limit: 255
      t.decimal  "sum",                    precision: 32, scale: 16, default: 0.0, null: false
      t.string   "type",       limit: 255
      t.string   "fund_tag",   limit: 255
    end

    add_foreign_key "liquidity_statuses", "orders"
  end
end
