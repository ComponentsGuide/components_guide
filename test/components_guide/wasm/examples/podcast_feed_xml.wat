(module
  (type (;0;) (func (result i32)))
  (type (;1;) (func (param i32) (result i64)))
  (type (;2;) (func (param i32) (result i32)))
  (type (;3;) (func (param i32 i32) (result i32)))
  (type (;4;) (func (param i32 i32 i32)))
  (type (;5;) (func))
  (type (;6;) (func (param i32)))
  (import "datasource" "get_episodes_count" (func (;0;) (type 0)))
  (import "datasource" "get_episode_pub_date_utc" (func (;1;) (type 1)))
  (import "datasource" "get_episode_duration_seconds" (func (;2;) (type 2)))
  (import "datasource" "write_episode_id" (func (;3;) (type 3)))
  (import "datasource" "write_episode_title" (func (;4;) (type 3)))
  (import "datasource" "write_episode_description" (func (;5;) (type 3)))
  (import "datasource" "write_episode_link_url" (func (;6;) (type 3)))
  (import "datasource" "write_episode_mp3_url" (func (;7;) (type 3)))
  (import "datasource" "get_episode_mp3_byte_count" (func (;8;) (type 2)))
  (import "datasource" "write_episode_content_html" (func (;9;) (type 3)))
  (func (;10;) (type 2) (param i32) (result i32)
    global.get 0
    global.get 0
    local.get 0
    i32.add
    global.set 0)
  (func (;11;) (type 4) (param i32 i32 i32)
    (local i32)
    loop  ;; label = @1
      local.get 3
      local.get 2
      i32.eq
      if  ;; label = @2
        return
      end
      local.get 0
      local.get 3
      i32.add
      local.get 1
      local.get 3
      i32.add
      i32.load8_u
      i32.store8
      local.get 3
      i32.const 1
      i32.add
      local.set 3
      br 0 (;@1;)
    end)
  (func (;12;) (type 4) (param i32 i32 i32)
    (local i32)
    loop  ;; label = @1
      local.get 3
      local.get 2
      i32.eq
      if  ;; label = @2
        return
      end
      local.get 0
      local.get 3
      i32.add
      local.get 1
      i32.store8
      local.get 3
      i32.const 1
      i32.add
      local.set 3
      br 0 (;@1;)
    end)
  (func (;13;) (type 3) (param i32 i32) (result i32)
    (local i32 i32 i32)
    loop (result i32)  ;; label = @1
      local.get 0
      local.get 2
      i32.add
      i32.load8_u
      local.set 3
      local.get 1
      local.get 2
      i32.add
      i32.load8_u
      local.set 4
      local.get 3
      i32.eqz
      if  ;; label = @2
        local.get 4
        i32.eqz
        return
      end
      local.get 3
      local.get 4
      i32.eq
      if  ;; label = @2
        local.get 2
        i32.const 1
        i32.add
        local.set 2
        br 1 (;@1;)
      end
      i32.const 0
      return
    end)
  (func (;14;) (type 2) (param i32) (result i32)
    (local i32)
    loop  ;; label = @1
      local.get 0
      local.get 1
      i32.add
      i32.load8_u
      if  ;; label = @2
        local.get 1
        i32.const 1
        i32.add
        local.set 1
        br 1 (;@1;)
      end
    end
    local.get 1)
  (func (;15;) (type 2) (param i32) (result i32)
    (local i32 i32)
    loop  ;; label = @1
      local.get 1
      i32.const 1
      i32.add
      local.set 1
      local.get 0
      i32.const 10
      i32.rem_u
      local.set 2
      local.get 0
      i32.const 10
      i32.div_u
      local.set 0
      local.get 0
      i32.const 0
      i32.gt_u
      br_if 0 (;@1;)
    end
    local.get 1)
  (func (;16;) (type 3) (param i32 i32) (result i32)
    (local i32 i32 i32)
    local.get 1
    local.get 0
    call 15
    i32.add
    local.set 3
    local.get 3
    local.set 2
    loop  ;; label = @1
      local.get 2
      i32.const 1
      i32.sub
      local.set 2
      local.get 0
      i32.const 10
      i32.rem_u
      local.set 4
      local.get 0
      i32.const 10
      i32.div_u
      local.set 0
      local.get 2
      i32.const 48
      local.get 4
      i32.add
      i32.store8
      local.get 0
      i32.const 0
      i32.gt_u
      br_if 0 (;@1;)
    end
    local.get 3)
  (func (;17;) (type 5)
    global.get 2
    i32.eqz
    if  ;; label = @1
      global.get 0
      global.set 1
    end
    global.get 2
    i32.const 1
    i32.add
    global.set 2)
  (func (;18;) (type 0) (result i32)
    global.get 2
    i32.const 0
    i32.gt_u
    if  ;; label = @1
      nop
    else
      unreachable
    end
    global.get 2
    i32.const 1
    i32.sub
    global.set 2
    global.get 2
    i32.eqz
    if  ;; label = @1
      global.get 0
      i32.const 0
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
    end
    global.get 1)
  (func (;19;) (type 6) (param i32)
    (local i32)
    local.get 0
    global.get 1
    i32.eq
    if  ;; label = @1
      return
    end
    local.get 0
    call 14
    local.set 1
    global.get 0
    local.get 0
    local.get 1
    call 11
    global.get 0
    local.get 1
    i32.add
    global.set 0)
  (func (;20;) (type 0) (result i32)
    global.get 0
    global.get 1
    i32.gt_u)
  (func (;21;) (type 2) (param i32) (result i32)
    call 17
    i32.const 270
    call 19
    local.get 0
    call 19
    i32.const 307
    call 19
    call 18)
  (func (;22;) (type 2) (param i32) (result i32)
    call 17
    i32.const 759
    call 19
    local.get 0
    call 19
    i32.const 762
    call 19
    call 18)
  (func (;23;) (type 3) (param i32 i32) (result i32)
    call 17
    i32.const 765
    call 19
    local.get 0
    call 19
    i32.const 767
    call 19
    local.get 1
    call 21
    call 19
    i32.const 759
    call 19
    local.get 0
    call 19
    i32.const 769
    call 19
    call 18)
  (func (;24;) (type 5)
    i32.const 65536
    global.set 0)
  (func (;25;) (type 5)
    (local i32 i32)
    call 0
    local.set 0
    local.get 0
    i32.eqz
    if  ;; label = @1
      return
    end
    loop  ;; label = @1
      call 17
      i32.const 264
      call 19
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 280
      call 19
      i32.const 286
      call 19
      i32.const 301
      call 19
      global.get 0
      i32.const 34
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 270
      call 19
      global.get 0
      local.get 1
      global.get 0
      call 3
      i32.add
      global.set 0
      i32.const 307
      call 19
      i32.const 311
      call 22
      drop
      i32.const 316
      call 19
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 270
      call 19
      global.get 0
      local.get 1
      global.get 0
      call 4
      i32.add
      global.set 0
      i32.const 307
      call 19
      i32.const 323
      call 22
      drop
      i32.const 329
      call 19
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 270
      call 19
      global.get 0
      local.get 1
      global.get 0
      call 4
      i32.add
      global.set 0
      i32.const 307
      call 19
      i32.const 343
      call 22
      drop
      i32.const 356
      call 19
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 270
      call 19
      global.get 0
      local.get 1
      global.get 0
      call 5
      i32.add
      global.set 0
      i32.const 307
      call 19
      i32.const 369
      call 22
      drop
      i32.const 381
      call 19
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 270
      call 19
      global.get 0
      local.get 1
      global.get 0
      call 5
      i32.add
      global.set 0
      i32.const 307
      call 19
      i32.const 398
      call 22
      drop
      i32.const 414
      call 22
      drop
      call 18
      drop
      local.get 1
      i32.const 1
      i32.add
      local.set 1
      local.get 1
      local.get 0
      i32.lt_s
      br_if 0 (;@1;)
    end)
  (func (;26;) (type 0) (result i32)
    call 17
    i32.const 419
    call 19
    i32.const 460
    call 19
    i32.const 465
    call 19
    i32.const 476
    call 19
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 480
    call 19
    i32.const 496
    call 19
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 539
    call 19
    i32.const 559
    call 19
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 607
    call 19
    i32.const 619
    call 19
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 652
    call 19
    i32.const 669
    call 19
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    global.get 0
    i32.const 62
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    global.get 0
    i32.const 10
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 710
    call 19
    global.get 0
    i32.const 62
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    global.get 0
    i32.const 10
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 323
    global.get 3
    call 23
    call 19
    i32.const 369
    global.get 4
    call 23
    call 19
    i32.const 398
    global.get 4
    call 23
    call 19
    i32.const 719
    global.get 5
    call 23
    call 19
    i32.const 733
    global.get 6
    call 23
    call 19
    i32.const 738
    global.get 7
    call 23
    call 19
    call 25
    i32.const 747
    call 22
    call 19
    i32.const 755
    call 22
    call 19
    call 18)
  (memory (;0;) 12)
  (global (;0;) (mut i32) (i32.const 65536))
  (global (;1;) (mut i32) (i32.const 0))
  (global (;2;) (mut i32) (i32.const 0))
  (global (;3;) (mut i32) (i32.const 255))
  (global (;4;) (mut i32) (i32.const 0))
  (global (;5;) (mut i32) (i32.const 0))
  (global (;6;) (mut i32) (i32.const 0))
  (global (;7;) (mut i32) (i32.const 261))
  (global (;8;) (mut i32) (i32.const 0))
  (global (;9;) (mut i32) (i32.const 0))
  (global (;10;) (mut i32) (i32.const 0))
  (global (;11;) (mut i32) (i32.const 0))
  (global (;12;) (mut i32) (i32.const 0))
  (global (;13;) (mut i32) (i32.const 0))
  (export "memory" (memory 0))
  (export "title" (global 3))
  (export "description" (global 4))
  (export "author" (global 5))
  (export "link" (global 6))
  (export "language" (global 7))
  (export "free_all" (func 24))
  (export "alloc" (func 10))
  (export "write_episodes_xml" (func 25))
  (export "text_xml" (func 26))
  (data (;0;) (i32.const 719) "itunes:author")
  (data (;1;) (i32.const 465) " version=\22")
  (data (;2;) (i32.const 356) "<description")
  (data (;3;) (i32.const 652) " xmlns:content=\22")
  (data (;4;) (i32.const 539) " xmlns:googleplay=\22")
  (data (;5;) (i32.const 270) "<![CDATA[")
  (data (;6;) (i32.const 311) "guid")
  (data (;7;) (i32.const 607) " xmlns:dc=\22")
  (data (;8;) (i32.const 759) "</")
  (data (;9;) (i32.const 255) "hello")
  (data (;10;) (i32.const 769) ">\0a")
  (data (;11;) (i32.const 747) "channel")
  (data (;12;) (i32.const 301) "false")
  (data (;13;) (i32.const 414) "item")
  (data (;14;) (i32.const 559) "http://www.google.com/schemas/play-podcasts/1.0")
  (data (;15;) (i32.const 323) "title")
  (data (;16;) (i32.const 316) "<title")
  (data (;17;) (i32.const 767) ">")
  (data (;18;) (i32.const 329) "<itunes:title")
  (data (;19;) (i32.const 733) "link")
  (data (;20;) (i32.const 480) " xmlns:itunes=\22")
  (data (;21;) (i32.const 343) "itunes:title")
  (data (;22;) (i32.const 765) "<")
  (data (;23;) (i32.const 619) "http://purl.org/dc/elements/1.1/")
  (data (;24;) (i32.const 496) "http://www.itunes.com/dtds/podcast-1.0.dtd")
  (data (;25;) (i32.const 369) "description")
  (data (;26;) (i32.const 381) "<itunes:subtitle")
  (data (;27;) (i32.const 710) "<channel")
  (data (;28;) (i32.const 476) "2.0")
  (data (;29;) (i32.const 738) "language")
  (data (;30;) (i32.const 460) "<rss")
  (data (;31;) (i32.const 261) "en")
  (data (;32;) (i32.const 755) "rss")
  (data (;33;) (i32.const 398) "itunes:subtitle")
  (data (;34;) (i32.const 264) "<item")
  (data (;35;) (i32.const 762) ">\0a")
  (data (;36;) (i32.const 280) "<guid")
  (data (;37;) (i32.const 669) "http://purl.org/rss/1.0/modules/content/")
  (data (;38;) (i32.const 286) " isPermaLink=\22")
  (data (;39;) (i32.const 419) "<?xml version=\221.0\22 encoding=\22UTF-8\22?>\0a")
  (data (;40;) (i32.const 307) "]]>"))
