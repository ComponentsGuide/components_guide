defmodule ComponentsGuide.Git.PktLineTest do
  use ExUnit.Case, async: true
  @moduletag timeout: 1000

  alias ComponentsGuide.Git.PktLine

  @example_upload_pack "303031652320736572766963653D6769742D75706C6F61642D7061636B0A3030303030313536613334643037663832393666633062313439316131323732306530393262356161333330643832662048454144006D756C74695F61636B207468696E2D7061636B20736964652D62616E6420736964652D62616E642D36346B206F66732D64656C7461207368616C6C6F772064656570656E2D73696E63652064656570656E2D6E6F742064656570656E2D72656C6174697665206E6F2D70726F677265737320696E636C7564652D746167206D756C74695F61636B5F64657461696C656420616C6C6F772D7469702D736861312D696E2D77616E7420616C6C6F772D726561636861626C652D736861312D696E2D77616E74206E6F2D646F6E652073796D7265663D484541443A726566732F68656164732F6D61737465722066696C746572206F626A6563742D666F726D61743D73686131206167656E743D6769742F6769746875622D673232383331376534376632350A303034643463393633373462363532343535646231656237316562326139333930386237643234626434646420726566732F68656164732F4275726E74436172616D656C2D70617463682D310A303033666133346430376638323936666330623134393161313237323065303932623561613333306438326620726566732F68656164732F6D61737465720A303034623666653238323866303366383666336463336433313938353435623031303963346462333261333520726566732F68656164732F72656E6F766174652F636F6E6669677572650A303033663666653238323866303366383666336463336433313938353435623031303963346462333261333520726566732F70756C6C2F31322F686561640A303034306365346262613431393932386233623238626434363635646133316435626166323863653538363220726566732F70756C6C2F31322F6D657267650A303033653463393633373462363532343535646231656237316562326139333930386237643234626434646420726566732F70756C6C2F362F686561640A303033656334343263346164326632323664366565613363663430623165363230333164333436613330346520726566732F746167732F76302E332E300A303033663365383630663462633733353566333566333833613436353033376161666139356364396135376220726566732F746167732F76302E342E31310A303034323761383830646638386664356538333438653161623164333434626366623133303337353563313320726566732F746167732F76302E342E31315E7B7D0A303034316465336461383461353930336136306564663930366166643034646362323863323831666131306420726566732F746167732F76302E342E31312D300A303034343364363764653133636661313663343532346161303931373431646562373036373930323530393920726566732F746167732F76302E342E31312D305E7B7D0A303033666164313432373266323134323536376262313634323637383964313137643130313636666334343320726566732F746167732F76302E342E31320A303034323632623663366231636166323535646466353432666563356538336634356161663033366136343520726566732F746167732F76302E342E31325E7B7D0A303033656237343036376264326261646437306136326636633161613038343335326666393936386235653320726566732F746167732F76302E342E370A303033656332633238333938656439613631383430383866336333626665356130653963633032323135653920726566732F746167732F76302E352E300A303033656435326639363062663765343964633830666231313966633733303530353961393438323035386220726566732F746167732F76302E352E310A30303030"
                       |> Base.decode16!()

  test "parse" do
    assert PktLine.decode(@example_upload_pack) == [
             %PktLine{
               ref: "HEAD",
               oid: "a34d07f8296fc0b1491a12720e092b5aa330d82f",
               attrs: [
                 {"thin-pack", true},
                 {"side-band", true},
                 {"side-band-64k", true},
                 {"ofs-delta", true},
                 {"shallow", true},
                 {"deepen-since", true},
                 {"deepen-not", true},
                 {"deepen-relative", true},
                 {"no-progress", true},
                 {"include-tag", true},
                 {"multi_ack_detailed", true},
                 {"allow-tip-sha1-in-want", true},
                 {"allow-reachable-sha1-in-want", true},
                 {"no-done", true},
                 {"symref", "HEAD:refs/heads/master"},
                 {"filter", true},
                 {"object-format", "sha1"},
                 {"agent", "git/github-g228317e47f25"}
               ],
               attrs_raw: [
                 "thin-pack",
                 "side-band",
                 "side-band-64k",
                 "ofs-delta",
                 "shallow",
                 "deepen-since",
                 "deepen-not",
                 "deepen-relative",
                 "no-progress",
                 "include-tag",
                 "multi_ack_detailed",
                 "allow-tip-sha1-in-want",
                 "allow-reachable-sha1-in-want",
                 "no-done",
                 "symref=HEAD:refs/heads/master",
                 "filter",
                 "object-format=sha1",
                 "agent=git/github-g228317e47f25"
               ]
             },
             %PktLine{
               ref: "refs/heads/BurntCaramel-patch-1",
               oid: "4c96374b652455db1eb71eb2a93908b7d24bd4dd",
               attrs: [],
               attrs_raw: []
             },
             %PktLine{
               ref: "refs/heads/master",
               oid: "a34d07f8296fc0b1491a12720e092b5aa330d82f",
               attrs: [],
               attrs_raw: []
             },
             %PktLine{
               ref: "refs/heads/renovate/configure",
               oid: "6fe2828f03f86f3dc3d3198545b0109c4db32a35",
               attrs: [],
               attrs_raw: []
             },
             %PktLine{
               ref: "refs/pull/12/head",
               oid: "6fe2828f03f86f3dc3d3198545b0109c4db32a35",
               attrs: [],
               attrs_raw: []
             },
             %PktLine{
               ref: "refs/pull/12/merge",
               oid: "ce4bba419928b3b28bd4665da31d5baf28ce5862",
               attrs: [],
               attrs_raw: []
             },
             %PktLine{
               ref: "refs/pull/6/head",
               oid: "4c96374b652455db1eb71eb2a93908b7d24bd4dd",
               attrs: [],
               attrs_raw: []
             },
             %PktLine{
               ref: "refs/tags/v0.3.0",
               oid: "c442c4ad2f226d6eea3cf40b1e62031d346a304e",
               attrs: [],
               attrs_raw: []
             },
             %PktLine{
               ref: "refs/tags/v0.4.11",
               oid: "3e860f4bc7355f35f383a465037aafa95cd9a57b",
               attrs: [],
               attrs_raw: []
             },
             %PktLine{
               ref: "refs/tags/v0.4.11^{}",
               oid: "7a880df88fd5e8348e1ab1d344bcfb1303755c13",
               attrs: [],
               attrs_raw: []
             },
             %PktLine{
               ref: "refs/tags/v0.4.11-0",
               oid: "de3da84a5903a60edf906afd04dcb28c281fa10d",
               attrs: [],
               attrs_raw: []
             },
             %PktLine{
               ref: "refs/tags/v0.4.11-0^{}",
               oid: "3d67de13cfa16c4524aa091741deb70679025099",
               attrs: [],
               attrs_raw: []
             },
             %PktLine{
               ref: "refs/tags/v0.4.12",
               oid: "ad14272f2142567bb16426789d117d10166fc443",
               attrs: [],
               attrs_raw: []
             },
             %PktLine{
               ref: "refs/tags/v0.4.12^{}",
               oid: "62b6c6b1caf255ddf542fec5e83f45aaf036a645",
               attrs: [],
               attrs_raw: []
             },
             %PktLine{
               ref: "refs/tags/v0.4.7",
               oid: "b74067bd2badd70a62f6c1aa084352ff9968b5e3",
               attrs: [],
               attrs_raw: []
             },
             %PktLine{
               ref: "refs/tags/v0.5.0",
               oid: "c2c28398ed9a6184088f3c3bfe5a0e9cc02215e9",
               attrs: [],
               attrs_raw: []
             },
             %PktLine{
               ref: "refs/tags/v0.5.1",
               oid: "d52f960bf7e49dc80fb119fc7305059a9482058b",
               attrs: [],
               attrs_raw: []
             }
           ]
  end
end
