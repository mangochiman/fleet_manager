module ApplicationHelper
    def number_to_currency(amount, options = {})
        options = {
        unit: "MK",
        precision: 2,
        delimiter: ",",
        separator: ".",
        format: "%u %n"
        }.merge(options)
        super(amount, options)
    end
end
