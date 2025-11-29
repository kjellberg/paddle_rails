# frozen_string_literal: true

module PaddleRails
  module ApplicationHelper
    # Returns the path to the billing dashboard.
    #
    # This is a convenience helper that provides a clean, global way to
    # reference the PaddleRails billing portal root path.
    #
    # @example
    #   <%= link_to "Manage Billing", billing_dashboard_path %>
    #
    # @return [String] the path to the billing dashboard
    def billing_dashboard_path
      paddle_rails.root_path
    end

    # Returns the URL to the billing dashboard.
    #
    # @example
    #   <%= link_to "Manage Billing", billing_dashboard_url %>
    #
    # @return [String] the URL to the billing dashboard
    def billing_dashboard_url
      paddle_rails.root_url
    end

    # Returns an SVG icon for the given card brand.
    #
    # @param brand [String] The card brand (e.g., "VISA", "MASTERCARD", "AMEX")
    # @param size [String] CSS classes for sizing (default: "w-8 h-5")
    # @return [String] The SVG markup (html_safe)
    def payment_method_icon(brand, size: "w-8 h-5")
      svg = case brand&.to_s&.upcase
            when "VISA"
              <<~SVG
                <svg class="#{size}" viewBox="0 0 48 32" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <rect width="48" height="32" rx="4" fill="#1A1F71"/>
                  <path d="M19.5 21H17L18.8 11H21.3L19.5 21Z" fill="white"/>
                  <path d="M28.1 11.2C27.5 11 26.7 10.7 25.7 10.7C23.2 10.7 21.4 12 21.4 13.9C21.4 15.3 22.7 16.1 23.7 16.6C24.7 17.1 25 17.4 25 17.9C25 18.6 24.1 18.9 23.3 18.9C22.2 18.9 21.6 18.8 20.7 18.4L20.3 18.2L19.9 20.7C20.6 21 21.8 21.3 23 21.3C25.7 21.3 27.4 20 27.4 18C27.4 16.9 26.7 16 25.2 15.3C24.3 14.8 23.7 14.5 23.7 14C23.7 13.5 24.3 13 25.4 13C26.3 13 27 13.2 27.5 13.4L27.8 13.5L28.1 11.2Z" fill="white"/>
                  <path d="M32.9 11H30.9C30.3 11 29.8 11.2 29.5 11.8L25.8 21H28.5L29 19.6H32.3L32.6 21H35L32.9 11ZM29.8 17.6C30 17 30.9 14.5 30.9 14.5C30.9 14.5 31.1 14 31.3 13.6L31.5 14.4C31.5 14.4 32 16.7 32.1 17.5H29.8V17.6Z" fill="white"/>
                  <path d="M15.4 11L12.9 17.8L12.6 16.3C12.1 14.7 10.6 13 8.9 12.1L11.2 21H14L18.2 11H15.4Z" fill="white"/>
                  <path d="M11.1 11H6.9L6.8 11.2C10.1 12 12.3 14 13.1 16.3L12.2 11.9C12.1 11.3 11.7 11.1 11.1 11Z" fill="#F9A51A"/>
                </svg>
              SVG
            when "MASTERCARD"
              <<~SVG
                <svg class="#{size}" viewBox="0 0 48 32" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <rect width="48" height="32" rx="4" fill="#000"/>
                  <circle cx="18" cy="16" r="8" fill="#EB001B"/>
                  <circle cx="30" cy="16" r="8" fill="#F79E1B"/>
                  <path d="M24 10.4C25.8 11.9 27 14 27 16C27 18 25.8 20.1 24 21.6C22.2 20.1 21 18 21 16C21 14 22.2 11.9 24 10.4Z" fill="#FF5F00"/>
                </svg>
              SVG
            when "AMEX", "AMERICAN EXPRESS"
              <<~SVG
                <svg class="#{size}" viewBox="0 0 48 32" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <rect width="48" height="32" rx="4" fill="#006FCF"/>
                  <path d="M10 16.5L12.5 11H15L18.5 19H16L15.3 17.5H12.2L11.5 19H9L10 16.5ZM13.7 13L12.8 15.5H14.7L13.7 13Z" fill="white"/>
                  <path d="M19 11H22L24 15L26 11H29V19H27V14L24.5 19H23.5L21 14V19H19V11Z" fill="white"/>
                  <path d="M30 11H37V12.8H32V14H36.8V15.8H32V17.2H37V19H30V11Z" fill="white"/>
                  <path d="M38 11H40.5L42 14L43.5 11H46L43 15.5L46 20H43.5L42 17L40.5 20H38L41 15.5L38 11Z" fill="white"/>
                </svg>
              SVG
            when "DISCOVER"
              <<~SVG
                <svg class="#{size}" viewBox="0 0 48 32" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <rect width="48" height="32" rx="4" fill="#fff"/>
                  <rect x="0.5" y="0.5" width="47" height="31" rx="3.5" stroke="#E5E7EB"/>
                  <path d="M0 16H24C24 22 29 28 36 28H48V32H0V16Z" fill="#F48024"/>
                  <circle cx="30" cy="16" r="6" fill="#F48024"/>
                  <text x="8" y="18" font-family="Arial" font-size="8" font-weight="bold" fill="#000">DISCOVER</text>
                </svg>
              SVG
            when "DINERS", "DINERS CLUB"
              <<~SVG
                <svg class="#{size}" viewBox="0 0 48 32" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <rect width="48" height="32" rx="4" fill="#0079BE"/>
                  <circle cx="24" cy="16" r="9" fill="white"/>
                  <path d="M19 16C19 13.2 20.8 10.9 23.3 10.2V21.8C20.8 21.1 19 18.8 19 16Z" fill="#0079BE"/>
                  <path d="M29 16C29 18.8 27.2 21.1 24.7 21.8V10.2C27.2 10.9 29 13.2 29 16Z" fill="#0079BE"/>
                </svg>
              SVG
            when "JCB"
              <<~SVG
                <svg class="#{size}" viewBox="0 0 48 32" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <rect width="48" height="32" rx="4" fill="#fff"/>
                  <rect x="0.5" y="0.5" width="47" height="31" rx="3.5" stroke="#E5E7EB"/>
                  <rect x="8" y="6" width="10" height="20" rx="2" fill="#0E4C96"/>
                  <rect x="19" y="6" width="10" height="20" rx="2" fill="#E01536"/>
                  <rect x="30" y="6" width="10" height="20" rx="2" fill="#00A14F"/>
                  <text x="10" y="19" font-family="Arial" font-size="6" font-weight="bold" fill="white">J</text>
                  <text x="22" y="19" font-family="Arial" font-size="6" font-weight="bold" fill="white">C</text>
                  <text x="33" y="19" font-family="Arial" font-size="6" font-weight="bold" fill="white">B</text>
                </svg>
              SVG
            when "UNIONPAY"
              <<~SVG
                <svg class="#{size}" viewBox="0 0 48 32" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <rect width="48" height="32" rx="4" fill="#1A4788"/>
                  <path d="M12 6H20L18 26H10L12 6Z" fill="#E21836"/>
                  <path d="M18 6H28L26 26H16L18 6Z" fill="#00447C"/>
                  <path d="M26 6H36L34 26H24L26 6Z" fill="#007B84"/>
                </svg>
              SVG
            else
              # Generic card icon
              <<~SVG
                <svg class="#{size}" viewBox="0 0 48 32" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <rect width="48" height="32" rx="4" fill="#6B7280"/>
                  <rect x="6" y="10" width="12" height="8" rx="1" fill="#9CA3AF"/>
                  <rect x="6" y="22" width="20" height="2" rx="1" fill="#9CA3AF"/>
                  <rect x="28" y="22" width="8" height="2" rx="1" fill="#9CA3AF"/>
                </svg>
              SVG
            end

      svg.html_safe
    end
  end
end
