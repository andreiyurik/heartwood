class AddGedcomColumnsForPhase2 < ActiveRecord::Migration[8.1]
  def change
    # gedcom_xref on events (for top-level EVEN records in GEDCOM 7.0)
    add_column :events, :gedcom_xref, :string

    # Raw store for unknown/custom tags — never drop data (see ADR-0004, gedcom.md)
    add_column :people,   :gedcom_raw, :json
    add_column :families, :gedcom_raw, :json
    add_column :events,   :gedcom_raw, :json
  end
end
