include DocumentParser
class CensusApi
  def call(document_type, document_number)
    response = nil
    get_document_number_variants(document_type, document_number).each do |variant|
      response = Response.new(get_response_body(document_type, variant))
      return response if response.valid?
    end
    response
  end

  class Response
    def initialize(body)
      @body = body
    end

    def valid?
      result[:exito] == "-1" && data.present?
    end

    def date_of_birth
      date = data[:fechaNacimiento].to_s.first(8)
      year = date.first(4)
      month = date.last(4).first(2)
      day = date.last(4).last(2)
      return nil unless day.present? && month.present? && year.present?

      Time.zone.local(year.to_i, month.to_i, day.to_i).to_date
    end

    def district_code
      data[:distrito]
    end

    def gender
      case data[:sexo]
      when "V"
        "male"
      when "M"
        "female"
      end
    end

    private

      def result
        @body[:res]
      end

      def data
        @body[:par][:l_habitante][:habitante] rescue {}
      end
  end

  private

    def get_response_body(document_type, document_number)
      if end_point_available?
        response = Faraday.post(url, request(document_type, document_number), headers)
        JSON.parse(response.body).deep_symbolize_keys!
      else
        stubbed_response(document_type, document_number)
      end
    end

    def url
      Rails.application.secrets.census_api_end_point
    end

    def request(document_type, document_number)
      {
        sec: {
          nonce: nonce,
          fecha: datetime,
          token: token,
          cli: Rails.application.secrets.census_api_cli,
          org: Rails.application.secrets.census_api_org,
          ent: Rails.application.secrets.census_api_ent,
          usu: Rails.application.secrets.census_api_usu,
          pwd: encrypted_password
        },
        par: {
          codigoTipoDocumento: document_type,
          documento: encrypted_document_number(document_number),
          busquedaExacta: -1
        }
      }.to_json
    end

    def nonce
      @nonce ||= Time.current.to_i
    end

    def datetime
      @datetime ||= Time.zone.at(@nonce).strftime("%Y%m%d%H%M%S")
    end

    def token
      Digest::SHA256.base64digest(nonce.to_s + datetime + Rails.application.secrets.census_api_public_key)
    end

    def encrypted_password
      Digest::SHA1.base64digest(Rails.application.secrets.census_api_pwd)
    end

    def encrypted_document_number(document_number)
      Base64.encode64(document_number).delete("\n")
    end

    def headers
      { "Content-Type" => "application/json" }
    end

    def end_point_available?
      Rails.env.staging? || Rails.env.production?
    end

    def stubbed_response(document_type, document_number)
      if (document_number == "12345678Z" || document_number == "12345678Y") && document_type == "1"
        stubbed_valid_response
      else
        stubbed_invalid_response
      end
    end

    def stubbed_valid_response
      {
        par: {
          l_habitante: {
            habitante: {
              fechaNacimiento: 19801231000000,
              sexo: "V",
              distrito: 1
            }
          }
        },
        res: {
          error: nil,
          exito: "-1",
          codigo: nil
        }
      }
    end

    def stubbed_invalid_response
      {
        par: nil,
        res: {
          error: "error message",
          exito: "0",
          codigo: "error code"
        }
      }
    end
end
