defmodule ComponentsGuide.Research.Sources.TypescriptTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Research.Sources.Typescript.{
    Parser,
    Interface,
    Namespace,
    GlobalVariable,
    GlobalFunction
  }

  @typescript_source ~S"""
  /*! *****************************************************************************
  Copyright (c) Microsoft Corporation. All rights reserved.
  Licensed under the Apache License, Version 2.0 (the "License"); you may not use
  this file except in compliance with the License. You may obtain a copy of the
  License at http://www.apache.org/licenses/LICENSE-2.0

  THIS CODE IS PROVIDED ON AN *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
  WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
  MERCHANTABLITY OR NON-INFRINGEMENT.

  See the Apache Version 2.0 License for specific language governing permissions
  and limitations under the License.
  ***************************************************************************** */



  /// <reference no-default-lib="true"/>


  /////////////////////////////
  /// Window APIs
  /////////////////////////////

  interface AddEventListenerOptions extends EventListenerOptions {
      once?: boolean;
      passive?: boolean;
      signal?: AbortSignal;
  }

  interface AesCbcParams extends Algorithm {
      iv: BufferSource;
  }

  /** A file-like object of immutable, raw data. Blobs represent data that isn't necessarily in a JavaScript-native format. The File interface is based on Blob, inheriting blob functionality and expanding it to support files on the user's system. */
  interface Blob {
      readonly size: number;
      readonly type: string;
      arrayBuffer(): Promise<ArrayBuffer>;
      slice(start?: number, end?: number, contentType?: string): Blob;
      stream(): ReadableStream<Uint8Array>;
      text(): Promise<string>;
  }

  declare var Blob: {
      prototype: Blob;
      new(blobParts?: BlobPart[], options?: BlobPropertyBag): Blob;
  };

  /**
   * Posts a message to the given window. Messages can be structured objects, e.g. nested objects and arrays, can contain JavaScript values (strings, numbers, Date objects, etc), and can contain certain data objects such as File Blob, FileList, and ArrayBuffer objects.
   *
   * Objects listed in the transfer member of options are transferred, not just cloned, meaning that they are no longer usable on the sending side.
   *
   * A target origin can be specified using the targetOrigin member of options. If not provided, it defaults to "/". This default restricts the message to same-origin targets only.
   *
   * If the origin of the target window doesn't match the given target origin, the message is discarded, to avoid information leakage. To send the message to the target regardless of origin, set the target origin to "*".
   *
   * Throws a "DataCloneError" DOMException if transfer array contains duplicate objects or if message could not be cloned.
   */
  declare function postMessage(message: any, targetOrigin: string, transfer?: Transferable[]): void;

  /** Moves the focus to the window's browsing context, if any. */
  declare function focus(): void;

  declare function requestAnimationFrame(callback: FrameRequestCallback): number;

  declare var console: Console;

  /** Holds useful CSS-related methods. No object with this interface are implemented: it contains only static methods and therefore is a utilitarian interface. */
  declare namespace CSS {
      function escape(ident: string): string;
      function supports(property: string, value: string): boolean;
      function supports(conditionText: string): boolean;
  }
  """

  test "parse" do
    assert Parser.parse(@typescript_source) == [
             %Interface{
               name: "AddEventListenerOptions",
               line_start: 24,
               line_end: 28
             },
             %Interface{
               name: "AesCbcParams",
               line_start: 30,
               line_end: 32
             },
             %Interface{
               name: "Blob",
               doc:
                 "A file-like object of immutable, raw data. Blobs represent data that isn't necessarily in a JavaScript-native format. The File interface is based on Blob, inheriting blob functionality and expanding it to support files on the user's system.",
               line_start: 34,
               line_end: 42
             },
             %GlobalVariable{
               name: "Blob",
               line_start: 44,
               line_end: 47
             },
             %GlobalFunction{
               name: "postMessage",
               doc:
                 ~S"""
                 Posts a message to the given window. Messages can be structured objects, e.g. nested objects and arrays, can contain JavaScript values (strings, numbers, Date objects, etc), and can contain certain data objects such as File Blob, FileList, and ArrayBuffer objects.

                 Objects listed in the transfer member of options are transferred, not just cloned, meaning that they are no longer usable on the sending side.

                 A target origin can be specified using the targetOrigin member of options. If not provided, it defaults to "/". This default restricts the message to same-origin targets only.

                 If the origin of the target window doesn't match the given target origin, the message is discarded, to avoid information leakage. To send the message to the target regardless of origin, set the target origin to "*".

                 Throws a "DataCloneError" DOMException if transfer array contains duplicate objects or if message could not be cloned.
                 """
                 |> String.trim_trailing(),
               line_start: 49,
               line_end: 60
             },
             %GlobalFunction{
               name: "focus",
               doc: "Moves the focus to the window's browsing context, if any.",
               line_start: 62,
               line_end: 63
             },
             %GlobalFunction{
               name: "requestAnimationFrame",
               line_start: 65,
               line_end: 65
             },
             %GlobalVariable{
               name: "console",
               doc: nil,
               line_start: 67,
               line_end: 67
             },
             %Namespace{
               name: "CSS",
               doc:
                 "Holds useful CSS-related methods. No object with this interface are implemented: it contains only static methods and therefore is a utilitarian interface.",
               line_start: 69,
               line_end: 74
             }
           ]
  end

  test "extract_line_ranges" do
    assert Parser.extract_line_ranges(@typescript_source, [
             24..28,
             %{line_start: 30, line_end: 32}
           ]) == [
             ~S"""
             interface AddEventListenerOptions extends EventListenerOptions {
                 once?: boolean;
                 passive?: boolean;
                 signal?: AbortSignal;
             }
             """
             |> String.trim_trailing(),
             ~S"""
             interface AesCbcParams extends Algorithm {
                 iv: BufferSource;
             }
             """
             |> String.trim_trailing()
           ]
  end
end
