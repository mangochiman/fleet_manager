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

    def time_of_day_greeting
        hour = Time.current.in_time_zone("UTC").hour
        case hour
        when  5..11 then "Good morning"
        when 12..16 then "Good afternoon"
        when 17..20 then "Good evening"
        else              "Good night"
        end
    end

end
