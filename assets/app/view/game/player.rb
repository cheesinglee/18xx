# frozen_string_literal: true

require 'lib/settings'
require 'view/game/companies'

module View
  module Game
    class Player < Snabberb::Component
      include Lib::Settings

      needs :player
      needs :game
      needs :display, default: 'inline-block'
      needs :show_hidden, default: false

      def render
        card_style = {
          border: @game.round.can_act?(@player) ? '4px solid' : '1px solid gainsboro',
          paddingBottom: '0.2rem',
        }
        card_style[:display] = @display

        divs = [
          render_title,
          render_body,
        ]

        if @player.companies.any? || @show_hidden
          divs << h(Companies, owner: @player, game: @game, show_hidden: @show_hidden)
        end

        h('div.player.card', { style: card_style }, divs)
      end

      def render_title
        props = {
          style: {
            padding: '0.4rem',
            backgroundColor: color_for(:bg2),
            color: color_for(:font2),
          },
        }

        h('div.player.title.nowrap', props, @player.name)
      end

      def render_body
        props = {
          style: {
            margin: '0.2rem',
            display: 'grid',
            grid: '1fr / auto-flow',
            justifyItems: 'center',
            alignItems: 'start',
          },
        }

        divs = [
          render_info,
        ]

        divs << render_shares if @player.shares.any?

        h(:div, props, divs)
      end

      def render_info
        num_certs = @player.num_certs
        cert_limit = @game.cert_limit

        td_cert_props = {
          style: {
            color: num_certs > cert_limit ? 'red' : 'currentColor',
          },
        }

        trs = [
          h(:tr, [
            h(:td, 'Cash'),
            h('td.right', @game.format_currency(@player.cash)),
          ]),
        ]

        if @game.active_step&.current_actions&.include?('bid')
          committed = @game.active_step.committed_cash(@player, @show_hidden)
          trs.concat([
            h(:tr, [
              h(:td, 'Committed'),
              h('td.right', @game.format_currency(committed)),
            ]),
            h(:tr, [
              h(:td, 'Available'),
              h('td.right', @game.format_currency(@player.cash - committed)),
            ]),
          ]) if committed.positive?
        end

        trs.concat([
          h(:tr, [
            h(:td, 'Value'),
            h('td.right', @game.format_currency(@player.value)),
          ]),
          h(:tr, [
            h(:td, 'Liquidity'),
            h('td.right', @game.format_currency(@game.liquidity(@player))),
          ]),
          h(:tr, [
            h(:td, 'Certs'),
            h('td.right', td_cert_props, "#{num_certs}/#{cert_limit}"),
          ]),
        ])

        if @player == @game.priority_deal_player
          props = {
            attrs: { colspan: '2' },
            style: {
              background: 'salmon',
              color: 'black',
              borderRadius: '3px',
            },
          }
          trs << h(:tr, [
            h('td.center.italic', props, 'Priority Deal'),
          ])
        end

        h(:table, trs)
      end

      def render_shares
        shares = @player
          .shares_by_corporation.reject { |_, s| s.empty? }
          .sort_by { |c, s| [s.sum(&:percent), c.president?(@player) ? 1 : 0, c.name] }
          .reverse
          .map { |c, s| render_corporation_shares(c, s) }

        h(:table, shares)
      end

      def render_corporation_shares(corporation, shares)
        td_props = {
          style: {
            padding: '0 0.2rem',
          },
        }
        div_props = {
          style: {
            height: '20px',
          },
        }
        logo_props = {
          attrs: {
            src: corporation.logo,
          },
          style: {
            height: '20px',
          },
        }

        president_marker = corporation.president?(@player) ? '*' : ''
        h('tr.row', [
          h('td.center', td_props, [h(:div, div_props, [h(:img, logo_props)])]),
          h(:td, td_props, corporation.name + president_marker),
          h('td.right', td_props, "#{shares.sum(&:percent)}%"),
        ])
      end
    end
  end
end
