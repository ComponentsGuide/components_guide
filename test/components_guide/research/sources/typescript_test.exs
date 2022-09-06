defmodule ComponentsGuide.Research.Sources.TypescriptTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Research.Sources.Typescript.{Parser, Interface}

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
  """

  test "parse" do
    assert Parser.parse(@typescript_source) == [
             %ComponentsGuide.Research.Sources.Typescript.Interface{
               name: "AddEventListenerOptions",
               line_start: 24,
               line_end: 28
             },
             %ComponentsGuide.Research.Sources.Typescript.Interface{
               name: "AesCbcParams",
               line_start: 30,
               line_end: 32
             },
             %ComponentsGuide.Research.Sources.Typescript.Interface{
               name: "Blob",
               line_start: 35,
               line_end: 42
             },
             %ComponentsGuide.Research.Sources.Typescript.GlobalVariable{
               name: "Blob",
               line_start: 44,
               line_end: 47
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
