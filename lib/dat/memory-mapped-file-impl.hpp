/* -*- c-basic-offset: 2 -*- */
/* Copyright(C) 2011 Brazil

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License version 2.1 as published by the Free Software Foundation.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#ifndef GRN_DAT_MEMORY_MAPPED_FILE_IMPL_HPP_
#define GRN_DAT_MEMORY_MAPPED_FILE_IMPL_HPP_

#ifdef WIN32
#include <Windows.h>
#endif  // WIN32

#include "dat.hpp"

namespace grn {
namespace dat {

class MemoryMappedFileImpl {
 public:
  MemoryMappedFileImpl();
  ~MemoryMappedFileImpl();

  void create(const char *path, UInt64 size);
  void open(const char *path);
  void close();

  void *ptr() const {
    return ptr_;
  }
  UInt64 size() const {
    return size_;
  }

  void swap(MemoryMappedFileImpl *rhs);

 private:
  void *ptr_;
  UInt64 size_;

#ifdef WIN32
  HANDLE file_;
  HANDLE map_;
  LPVOID addr_;
#else  // WIN32
  int fd_;
  void *addr_;
  ::size_t length_;
#endif  // WIN32

  void create_(const char *path, UInt64 size);
  void open_(const char *path);

  // Disallows copy and assignment.
  MemoryMappedFileImpl(const MemoryMappedFileImpl &);
  MemoryMappedFileImpl &operator=(const MemoryMappedFileImpl &);
};

}  // namespace dat
}  // namespace grn

#endif  // GRN_DAT_MEMORY_MAPPED_FILE_IMPL_HPP_