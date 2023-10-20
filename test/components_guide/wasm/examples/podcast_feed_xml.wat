(module
  (type (;0;) (func (result i32)))
  (type (;1;) (func (param i32 i32) (result i32)))
  (type (;2;) (func (param i32) (result i32)))
  (type (;3;) (func (param i32 i32 i32)))
  (type (;4;) (func))
  (type (;5;) (func (param i32)))
  (import "datasource" "get_episodes_count" (func (;0;) (type 0)))
  (import "datasource" "write_episode_id" (func (;1;) (type 1)))
  (import "datasource" "get_episode_pub_date_utc" (func (;2;) (type 2)))
  (import "datasource" "get_episode_duration_seconds" (func (;3;) (type 2)))
  (import "datasource" "write_episode_title" (func (;4;) (type 1)))
  (import "datasource" "write_episode_author" (func (;5;) (type 1)))
  (import "datasource" "write_episode_description" (func (;6;) (type 1)))
  (import "datasource" "write_episode_link_url" (func (;7;) (type 1)))
  (import "datasource" "write_episode_mp3_url" (func (;8;) (type 1)))
  (import "datasource" "get_episode_mp3_byte_count" (func (;9;) (type 2)))
  (import "datasource" "write_episode_content_html" (func (;10;) (type 1)))
  (func (;11;) (type 2) (param i32) (result i32)
    global.get 0
    global.get 0
    local.get 0
    i32.add
    global.set 0)
  (func (;12;) (type 3) (param i32 i32 i32)
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
  (func (;13;) (type 3) (param i32 i32 i32)
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
  (func (;14;) (type 1) (param i32 i32) (result i32)
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
  (func (;15;) (type 2) (param i32) (result i32)
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
  (func (;16;) (type 2) (param i32) (result i32)
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
  (func (;17;) (type 1) (param i32 i32) (result i32)
    (local i32 i32 i32)
    local.get 1
    local.get 0
    call 16
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
  (func (;18;) (type 4)
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
  (func (;19;) (type 0) (result i32)
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
  (func (;20;) (type 5) (param i32)
    (local i32)
    local.get 0
    global.get 1
    i32.eq
    if  ;; label = @1
      return
    end
    local.get 0
    call 15
    local.set 1
    global.get 0
    local.get 0
    local.get 1
    call 12
    global.get 0
    local.get 1
    i32.add
    global.set 0)
  (func (;21;) (type 0) (result i32)
    global.get 0
    global.get 1
    i32.gt_u)
  (func (;22;) (type 2) (param i32) (result i32)
    call 18
    i32.const 298
    call 20
    local.get 0
    call 20
    i32.const 308
    call 20
    call 19)
  (func (;23;) (type 2) (param i32) (result i32)
    call 18
    i32.const 760
    call 20
    local.get 0
    call 20
    i32.const 763
    call 20
    call 19)
  (func (;24;) (type 1) (param i32 i32) (result i32)
    call 18
    i32.const 766
    call 20
    local.get 0
    call 20
    i32.const 768
    call 20
    local.get 1
    call 22
    drop
    i32.const 760
    call 20
    local.get 0
    call 20
    i32.const 770
    call 20
    call 19)
  (func (;25;) (type 4)
    i32.const 65536
    global.set 0)
  (func (;26;) (type 4)
    (local i32 i32)
    call 0
    local.set 0
    local.get 0
    i32.eqz
    if  ;; label = @1
      return
    end
    loop  ;; label = @1
      call 18
      i32.const 265
      call 20
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 271
      call 20
      i32.const 277
      call 20
      i32.const 292
      call 20
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
      i32.const 298
      call 20
      global.get 0
      local.get 1
      global.get 0
      call 1
      i32.add
      global.set 0
      i32.const 308
      call 20
      i32.const 312
      call 23
      drop
      i32.const 317
      call 20
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 298
      call 20
      global.get 0
      local.get 1
      global.get 0
      call 4
      i32.add
      global.set 0
      i32.const 308
      call 20
      i32.const 324
      call 23
      drop
      i32.const 330
      call 20
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 298
      call 20
      global.get 0
      local.get 1
      global.get 0
      call 4
      i32.add
      global.set 0
      i32.const 308
      call 20
      i32.const 344
      call 23
      drop
      i32.const 357
      call 20
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 298
      call 20
      global.get 0
      local.get 1
      global.get 0
      call 6
      i32.add
      global.set 0
      i32.const 308
      call 20
      i32.const 370
      call 23
      drop
      i32.const 382
      call 20
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 298
      call 20
      global.get 0
      local.get 1
      global.get 0
      call 6
      i32.add
      global.set 0
      i32.const 308
      call 20
      i32.const 399
      call 23
      drop
      i32.const 415
      call 23
      drop
      call 19
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
  (func (;27;) (type 0) (result i32)
    call 18
    i32.const 420
    call 20
    i32.const 461
    call 20
    i32.const 466
    call 20
    i32.const 477
    call 20
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 481
    call 20
    i32.const 497
    call 20
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 540
    call 20
    i32.const 560
    call 20
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 608
    call 20
    i32.const 620
    call 20
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 653
    call 20
    i32.const 670
    call 20
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
    i32.const 711
    call 20
    global.get 0
    i32.const 62
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 324
    global.get 3
    call 24
    drop
    i32.const 370
    global.get 4
    call 24
    drop
    i32.const 399
    global.get 4
    call 24
    drop
    i32.const 720
    global.get 5
    call 24
    drop
    i32.const 734
    global.get 6
    call 24
    drop
    i32.const 739
    global.get 7
    call 24
    drop
    call 26
    i32.const 748
    call 23
    drop
    i32.const 756
    call 23
    drop
    call 19)
  (memory (;0;) 2)
  (global (;0;) (mut i32) (i32.const 65536))
  (global (;1;) (mut i32) (i32.const 0))
  (global (;2;) (mut i32) (i32.const 0))
  (global (;3;) (mut i32) (i32.const 255))
  (global (;4;) (mut i32) (i32.const 261))
  (global (;5;) (mut i32) (i32.const 261))
  (global (;6;) (mut i32) (i32.const 261))
  (global (;7;) (mut i32) (i32.const 262))
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
  (export "free_all" (func 25))
  (export "alloc" (func 11))
  (export "write_episodes_xml" (func 26))
  (export "text_xml" (func 27))
  (data (;0;) (i32.const 720) "itunes:author")
  (data (;1;) (i32.const 466) " version=\22")
  (data (;2;) (i32.const 357) "<description")
  (data (;3;) (i32.const 653) " xmlns:content=\22")
  (data (;4;) (i32.const 540) " xmlns:googleplay=\22")
  (data (;5;) (i32.const 298) "<![CDATA[")
  (data (;6;) (i32.const 312) "guid")
  (data (;7;) (i32.const 261) "")
  (data (;8;) (i32.const 608) " xmlns:dc=\22")
  (data (;9;) (i32.const 760) "</")
  (data (;10;) (i32.const 255) "hello")
  (data (;11;) (i32.const 770) ">\0a")
  (data (;12;) (i32.const 748) "channel")
  (data (;13;) (i32.const 292) "false")
  (data (;14;) (i32.const 415) "item")
  (data (;15;) (i32.const 560) "http://www.google.com/schemas/play-podcasts/1.0")
  (data (;16;) (i32.const 324) "title")
  (data (;17;) (i32.const 317) "<title")
  (data (;18;) (i32.const 768) ">")
  (data (;19;) (i32.const 330) "<itunes:title")
  (data (;20;) (i32.const 734) "link")
  (data (;21;) (i32.const 481) " xmlns:itunes=\22")
  (data (;22;) (i32.const 344) "itunes:title")
  (data (;23;) (i32.const 766) "<")
  (data (;24;) (i32.const 620) "http://purl.org/dc/elements/1.1/")
  (data (;25;) (i32.const 497) "http://www.itunes.com/dtds/podcast-1.0.dtd")
  (data (;26;) (i32.const 370) "description")
  (data (;27;) (i32.const 382) "<itunes:subtitle")
  (data (;28;) (i32.const 711) "<channel")
  (data (;29;) (i32.const 477) "2.0")
  (data (;30;) (i32.const 739) "language")
  (data (;31;) (i32.const 461) "<rss")
  (data (;32;) (i32.const 262) "en")
  (data (;33;) (i32.const 756) "rss")
  (data (;34;) (i32.const 399) "itunes:subtitle")
  (data (;35;) (i32.const 265) "<item")
  (data (;36;) (i32.const 763) ">\0a")
  (data (;37;) (i32.const 271) "<guid")
  (data (;38;) (i32.const 670) "http://purl.org/rss/1.0/modules/content/")
  (data (;39;) (i32.const 277) " isPermaLink=\22")
  (data (;40;) (i32.const 420) "<?xml version=\221.0\22 encoding=\22UTF-8\22?>\0a")
  (data (;41;) (i32.const 308) "]]>"))
