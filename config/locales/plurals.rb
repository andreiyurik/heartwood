# Rails ships only English plural rules; Russian needs one/few/many by the last digits.
{
  ru: {
    i18n: {
      plural: {
        keys: %i[ one few many other ],
        rule: ->(count) do
          return :other unless count.is_a?(Integer)

          tens, units = count.abs % 100, count.abs % 10
          if units == 1 && tens != 11 then :one
          elsif (2..4).cover?(units) && !(12..14).cover?(tens) then :few
          else :many
          end
        end
      }
    }
  }
}
