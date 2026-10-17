defmodule CaptainNotesWeb.EmptyStateComponents do
  use Phoenix.Component
  import CaptainNotesWeb.CoreComponents, only: [brand_logo: 1, icon: 1]

  attr :holiday, :map, required: true

  def holiday_placeholder(assigns) do
    ~H"""
    <div id="school-holiday" class="holiday-placeholder" data-holiday={@holiday.kind}>
      <.illustration variant={@holiday.kind} />
      <h3>C'est les vacances</h3>
      <button id="holiday-return" type="button" phx-click="holiday-return" class="btn holiday-return">
        Voir la semaine de rentrée <.icon name="hero-arrow-right" class="size-4" />
      </button>
      <p>
        Reprise le
        <time datetime={Date.to_iso8601(@holiday.return_date)}>
          {return_label(@holiday.return_date)}
        </time>
      </p>
    </div>
    """
  end

  attr :variant, :atom,
    default: :default,
    values: [:default, :autumn, :christmas, :winter, :spring, :summer]

  def illustration(assigns) do
    ~H"""
    <div class="empty-illustration" data-illustration={@variant} aria-hidden="true">
      <svg viewBox="0 0 240 180" focusable="false">
        <path
          class="illustration-backdrop"
          d="M29 62C49 35 77 27 106 41S151 48 181 62s51 40 32 69-61 26-92 29S49 159 26 139 12 85 29 62Z"
        />
        <.scenery variant={@variant} />
      </svg>
      <.brand_logo variant="simple" class="illustration-logo" />
      <svg
        :if={@variant in [:winter, :summer]}
        class="illustration-accessories"
        viewBox="0 0 240 180"
        focusable="false"
      >
        <path
          :if={@variant == :winter}
          d="m117 61 17-7 28 13q6 4 3 7-4 3-9-2-6 3-10-3-7 2-10-4-8 1-11-2Z"
          fill="#eff7ff"
        />
        <g
          :if={@variant == :summer}
          stroke="#edb64e"
          stroke-width="4"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path
            d="M92 107q12-6 24 0v9q-2 13-13 9-10-4-11-18Zm36 0q12-6 24 0-1 14-11 18-11 4-13-9Z"
            fill="#64533f"
          />
          <path d="M116 110q6-5 12 0m-40-5 4 2m60 0 4-2" fill="none" />
        </g>
      </svg>
    </div>
    """
  end

  defp scenery(%{variant: :default} = assigns) do
    ~H"""
    <path
      class="illustration-cloud"
      d="M31 139q-2-16 15-16 5-23 28-13 11-8 23 1 15-18 33-1 16-11 29 1 20-6 25 11 22-3 24 14 10 2 8 10-4 13-93 13-93 0-98-12-2-5 6-8Z"
    />
    <g fill="#f4bd55">
      <.sparkle x={46} y={58} />
      <.sparkle x={194} y={96} />
    </g>
    <g class="illustration-dots">
      <circle cx="33" cy="92" r="3" /><circle cx="46" cy="106" r="2.5" />
      <circle cx="183" cy="68" r="3" /><circle cx="186" cy="121" r="2.5" />
    </g>
    """
  end

  defp scenery(%{variant: :autumn} = assigns) do
    ~H"""
    <.sun />
    <ellipse cx="121" cy="148" rx="38" ry="6" class="illustration-shadow" />
    <g transform="translate(39 43) rotate(-18)"><.autumn_leaf /></g>
    <g transform="translate(203 131) rotate(105) scale(.85)"><.autumn_leaf /></g>
    <path
      d="M33 101q3 15 18 21m-10-29q4 12 14 16"
      fill="none"
      stroke="#b8773240"
      stroke-width="2"
      stroke-linecap="round"
    />
    """
  end

  defp scenery(%{variant: :christmas} = assigns) do
    ~H"""
    <ellipse cx="122" cy="151" rx="95" ry="9" fill="#f6d59a" opacity=".35" />
    <rect x="44" y="136" width="9" height="21" rx="2" fill="#b98750" />
    <path
      d="M49 58 32 88q-2 4 9 4l-17 23q-3 6 11 5l-19 23q30 11 62 0l-19-23q14 1 11-5L55 92q11 0 8-4Z"
      fill="currentColor"
      opacity=".85"
    />
    <g fill="#edb64e">
      <circle cx="49" cy="78" r="4" /><circle cx="57" cy="110" r="4" /><circle cx="36" cy="134" r="4" />
    </g>
    <g fill="#e58270"><circle cx="39" cy="99" r="4" /><circle cx="60" cy="137" r="3" /></g>
    <rect x="179" y="124" width="37" height="31" rx="2" fill="#eb8266" />
    <rect x="176" y="118" width="43" height="10" rx="2" fill="#f39678" />
    <path d="M197 120v35" stroke="#f4c45c" stroke-width="6" />
    <path
      d="M197 118c-22-2-20-19-10-15 7 3 10 15 10 15s20-7 16-14c-5-8-17 5-16 14Z"
      fill="none"
      stroke="#f4c45c"
      stroke-width="3"
    />
    <g fill="#f4bd55"><.sparkle x={66} y={35} /><.sparkle x={197} y={64} /></g>
    """
  end

  defp scenery(%{variant: :winter} = assigns) do
    ~H"""
    <path d="M20 137q24-46 58-8 21-17 41 3 29-28 50-5 35-35 56 11Z" fill="#c5def2" />
    <ellipse cx="122" cy="148" rx="106" ry="14" fill="#e6f1fb" />
    <g stroke="#8bb9dc" stroke-width="2.5" stroke-linecap="round" fill="none">
      <.snowflake x={47} y={62} /><.snowflake x={181} y={29} /><.snowflake x={26} y={105} />
    </g>
    <g transform="rotate(-12 193 106)">
      <path d="M182 142V74q0-18 8-18t8 18v68Z" fill="#77a9cc" />
      <path d="M182 88h16m-16 16h16" stroke="#bdd8ed" stroke-width="5" />
    </g>
    <g transform="rotate(19 204 105)">
      <path d="M197 144V76q0-18 8-18t8 18v68Z" fill="#8ab7d8" />
      <path d="M197 90h16m-16 16h16" stroke="#d8e9f5" stroke-width="5" />
    </g>
    <path d="m187 106-7 45m27-44 10 42" stroke="#c69854" stroke-width="2.5" stroke-linecap="round" />
    """
  end

  defp scenery(%{variant: :spring} = assigns) do
    ~H"""
    <ellipse cx="120" cy="152" rx="98" ry="9" fill="#f6d59a" opacity=".3" />
    <path
      d="M40 147V99m0 29q-21 0-20-20 19 2 20 20Zm0-10q22 0 22-20-20 3-22 20Zm148 29v-35m0 25q-17-2-14-18 14 3 14 18Zm0 5q20-3 19-19-17 4-19 19Z"
      fill="#9eb785"
      stroke="#9eb785"
      stroke-width="3"
      stroke-linejoin="round"
    />
    <path d="M40 104q-23-7-16-29 5-5 10 5 6-18 12-1 11-11 12-1 1 20-18 26Z" fill="#ef9c91" />
    <g fill="#f3bf57" transform="translate(188 105)">
      <ellipse cy="-10" rx="5" ry="9" /><ellipse cy="10" rx="5" ry="9" />
      <ellipse cy="-10" rx="5" ry="9" transform="rotate(60)" /><ellipse
        cy="10"
        rx="5"
        ry="9"
        transform="rotate(60)"
      />
      <ellipse cy="-10" rx="5" ry="9" transform="rotate(120)" /><ellipse
        cy="10"
        rx="5"
        ry="9"
        transform="rotate(120)"
      />
      <circle r="5" fill="#b6894a" />
    </g>
    <path d="M48 145c0-25 13-39 20-39s21 14 21 39c0 18-41 18-41 0" fill="#f4c15a" />
    <path
      d="m51 130 7-4 7 4 7-4 7 4 7-4m-34 19 7-4 7 4 7-4 7 4"
      fill="none"
      stroke="#fff5d9"
      stroke-width="3"
    />
    <path d="M76 149c0-17 9-29 15-29s16 12 16 29c0 13-31 13-31 0" fill="#f0a397" />
    <g fill="#fff0e5">
      <circle cx="90" cy="132" r="2" /><circle cx="84" cy="143" r="2" /><circle
        cx="98"
        cy="145"
        r="2"
      /><circle cx="91" cy="154" r="2" />
    </g>
    <g transform="translate(190 48) rotate(-25)">
      <path
        d="M0 0c-25-23-19-34-9-26C0-21 0 0 0 0S17-24 24-14C29-5 0 0 0 0c23 1 22 16 10 12C5 10 0 0 0 0s-15 13-18 4C-20-2 0 0 0 0Z"
        fill="#f29d87"
      />
      <path d="m-6-14 11 27" stroke="#b38355" stroke-width="2" stroke-linecap="round" />
    </g>
    """
  end

  defp scenery(%{variant: :summer} = assigns) do
    ~H"""
    <.sun />
    <path d="M167 137q16 2 28-15t25-9q-13-3-13 9 3 18 26 9-9 30-60 15Z" fill="#89c8db" />
    <path
      d="M169 148q27 10 55-4"
      fill="none"
      stroke="#cce7ec"
      stroke-width="4"
      stroke-linecap="round"
    />
    <ellipse cx="111" cy="153" rx="86" ry="12" fill="#f9dfab" />
    <path d="m40 63 27 84" stroke="#ad8753" stroke-width="3" stroke-linecap="round" />
    <path d="M14 87q-1-41 26-44 36-4 53 28Z" fill="#f4876c" />
    <path d="M40 43Q26 64 36 81l27-6Q57 51 40 43Z" fill="#ffe6bd" />
    <g fill="#eac48d">
      <circle cx="48" cy="155" r="2" /><circle cx="169" cy="155" r="2" /><circle
        cx="158"
        cy="149"
        r="1.5"
      />
    </g>
    """
  end

  defp sun(assigns) do
    ~H"""
    <g fill="none" stroke="#f5b747" stroke-width="2.5" stroke-linecap="round">
      <circle cx="183" cy="35" r="19" fill="#f5b747" stroke="none" />
      <path d="M183 6V1m0 68v-5m29-29h5m-68 0h5m9-20-4-4m48 48-4-4m0-40 4-4m-48 48 4-4" />
    </g>
    """
  end

  defp sparkle(assigns) do
    ~H"""
    <path transform={"translate(#{@x} #{@y})"} d="m0-10 3 7 7 3-7 3-3 7-3-7-7-3 7-3Z" />
    """
  end

  defp snowflake(assigns) do
    ~H"""
    <g transform={"translate(#{@x} #{@y})"}>
      <path d="M0-13v26m-11-19 22 12m-22 0L11-6M-4-10l4 3 4-3m-8 20 4-3 4 3m-14-11 5-2v-5m15 9-5 2v5m0-16v5l5 2M-10 7l5-2v5" />
    </g>
    """
  end

  defp autumn_leaf(assigns) do
    ~H"""
    <path
      fill="#e9a34b"
      d="M0 0C13-5 33 1 38 10l-12 1c14 6 20 16 18 23l-14-3c6 9 5 18 0 22C17 48 3 36 0 23L-6 12l8 1Z"
    />
    <path
      d="M-6-10 30 45M6 9l15 2M14 23l18 4M14 23l-4 12"
      fill="none"
      stroke="#b87732"
      stroke-width="1.8"
      stroke-linecap="round"
      stroke-linejoin="round"
    />
    """
  end

  defp return_label(date) do
    day =
      Enum.at(~w(lundi mardi mercredi jeudi vendredi samedi dimanche), Date.day_of_week(date) - 1)

    month =
      Enum.at(
        ~w(janvier février mars avril mai juin juillet août septembre octobre novembre décembre),
        date.month - 1
      )

    "#{day} #{date.day} #{month}"
  end
end
